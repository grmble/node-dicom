"use strict";

/*jslint nomen: true */

var util = require('util'),
    fs = require('fs'),
    path = require('path'),
    printf = require('printf'),
    log4js = require('log4js'),
    ReadBuffer = require('./readbuffer').ReadBuffer,
    uids = require('./uids'),
    tags = require('./tags'),
    vr = require('./vr');


var verbose = false;
var log = log4js.getLogger('dicomreader');

var vtrace = function() {
    if (verbose && log.isDebugEnabled) {
        log.debug.apply(log.debug, arguments);
    }
};

var DicomReader = function (stream, ts) {
    ReadBuffer.call(this, stream);
    this.ts = ts || uids.ts.ExplicitVRLittleEndian;
    this.nested = [];
};
util.inherits(DicomReader, ReadBuffer);

var tagsWithoutVR = {};
tagsWithoutVR[tags.Item] = true;
tagsWithoutVR[tags.ItemDelimitationItem] = true;
tagsWithoutVR[tags.SequenceDelimitationItem] = true;

DicomReader.prototype.readDataElement = function (cont) {
    var group, element, tag, vrStr, valueLengthBytes,
        VRConstructor, dataElement,
        eofCheck, emitAndCont, buff4CB, buff8CB, handleNested,
        self = this,
        endianess = self.ts.endianess(),
        offset = self.streamPosition,
        w16u = endianess.getUInt16;

    buff8CB = function (buffer) {
        group = w16u(buffer, 0);
        element = w16u(buffer, 1);
        tag = printf("(%04X,%04X)", group, element);
        vtrace("DicomReader.readDataElement: tag=", tag);

        if (!self.ts.explicit) {
            vrStr = tags.tag(tag).vr;
        } else if (tagsWithoutVR[tag]) {
            vrStr = 'NoVR';
        } else if (!tagsWithoutVR[tag]) {
            vrStr = buffer.slice(4, 6).toString();
        }
        vtrace("DicomReader.readDataElement: vrStr=", vrStr);

        VRConstructor = endianess[vrStr];
        if (!VRConstructor) {
            self.error("No VR for" + vrStr);
        } else {
            dataElement = new VRConstructor({tag: tag, offset: offset});
            valueLengthBytes = self.ts.valueLengthBytes(dataElement);
            vtrace("DicomReader.readDataElement: value length bytes:", valueLengthBytes);
            if (valueLengthBytes === 2) {
                dataElement.setElementLength(w16u(buffer, 3));
                handleNested();
            } else if (valueLengthBytes === 4) {
                dataElement.setElementLength(endianess.getUInt32(buffer, 1));
                handleNested();
            } else if (valueLengthBytes === 6) {
                self.read(4, buff4CB);
            } else {
                self.error("Huh? no valueLengthBytes for vr/ts");
            }
        }
    };

    buff4CB = function (buffer) {
        dataElement.setElementLength(endianess.getUInt32(buffer, 0));
        handleNested();
    };

    handleNested = function () {
        var endedElement, endOffset,
            nested = self.nested,
            topNested = nested[nested.length - 1];
        if (dataElement.nesting || dataElement.encapsulated) {
            if (topNested && topNested.encapsulated &&
                    dataElement.tag === tags.Item) {
                // fix up item in encapsulated pixel data so
                // its data will be streamed
                dataElement.encapsulated = true;
                dataElement.valueLength = dataElement.nestedLength;
                dataElement.nestedLength = undefined;
                vtrace("DicomReader.readDataElement encapsulated:", dataElement.valueLength);
                // DO NOT NEST
                emitAndCont();
            } else {
                vtrace("DicomReader.readDataELement nesting:", dataElement.nestedLength);
                nested.push(dataElement);
                emitAndCont();
            }
        } else if (dataElement.endsNesting) {
            vtrace("DicomReader.readDataElement endsNesting", dataElement.tag);
            endedElement = nested.pop();
            if (endedElement.nestedLength) {
                self.error("Internal error, explicit end tag ends limited sq/item: " +
                        endedElement + " ended by " + dataElement);
            } else {
                self.emit('endelement', endedElement);
                emitAndCont();
            }
        } else {
            topNested = nested[nested.length - 1];
            if (topNested && topNested.nestedLength) {
                endOffset = topNested.offset +  topNested.nestedLength;
                if (dataElement.offset > endOffset) {
                    vtrace("DicomReader.readDataElement: end of limited nesting:", topNested);
                    nested.pop();
                }
                self.emit('endelement', topNested);
            }
            emitAndCont();
        }
    };

    emitAndCont = function () {
        vtrace("DicomReader.readDataElement: emitting:", dataElement);
        self.emit('element', dataElement);
        cont(dataElement);
    };

    self.read(8, buff8CB);
};

DicomReader.prototype.streamDataElementValue = function (dataElement, cont) {
    var self = this;
    self.streamData(dataElement.valueLength, function () {
        if (dataElement.encapsulated || (!dataElement.endsNesting && !dataElement.nesting)) {
            vtrace("DicomReader.streamDataElementValue: emitting regular element end", dataElement);
            self.emit('endelement', dataElement);
        }
        cont();
    });
};

DicomReader.prototype.readDataset = function (cont) {
    var eofCaller, eofChecker, streamer,
        self = this;

    eofCaller = function () {
        self.eof(eofChecker);
    };

    eofChecker = function (eof) {
        vtrace("DicomReader.readDataset: eof", eof);
        if (eof) {
            if (self.nested.length === 0) {
                vtrace("EOF OK");
                cont();
            } else {
                self.error(new Error("EOF with pending nested elements:" + 
                            self.nested[self.nested.length - 1]));
            }
        } else {
            self.nextTick(self.readDataElement, streamer);
        }
    };

    streamer = function (dataElement) {
        if (dataElement.valueLength !== undefined) {
            self.streamDataElementValue(dataElement, eofCaller);
        } else {
            eofCaller();
        }
    };

    eofCaller();
};

DicomReader.prototype.readPreamble = function (cont) {
    this.read(128, cont);
};

DicomReader.prototype.readDicomHeader = function (cont) {
    var self = this;
    this.read(4, function (buffer) {
        var str = buffer.toString('ascii');
        if (str === 'DICM') {
            cont();
        } else {
            self.error("Missing DICOM Header - not a dicom file:" + str);
        }
    });
};

DicomReader.prototype.readMetaInfo = function (cont) {
    var loopChecker, loopFn, nextTS, metaInfoEnd,
        tsUID = tags.TransferSyntaxUID,
        self = this;

    loopFn = function (dataElement) {
        if (dataElement.valueLength !== undefined) {
            self.read(dataElement.valueLength, function (buffer) {
                if (dataElement.tag === tsUID) {
                    nextTS = uids.uid(dataElement.getValues(buffer)[0]);
                    vtrace("DicomReader.readMetaInfo: next TS:", nextTS);
                }
            });
        }
        loopChecker();
    };

    loopChecker = function () {
        if (self.streamPosition >= metaInfoEnd) {
            vtrace("DicomReader.readMetaInfo: reading metainfo done");
            if (nextTS !== undefined) {
                vtrace("DicomReader.readMetaInfo: switching transfer syntax:" + nextTS.name);
                self.ts = nextTS;
            }
            cont();
        } else {
            self.nextTick(self.readDataElement, loopFn);
        }
    };

    self.readDataElement(function (dataElement) {
        if (dataElement.tag === tags.FileMetaInformationGroupLength) {
            self.read(dataElement.valueLength, function (buffer) {
                metaInfoEnd = self.streamPosition + dataElement.getValues(buffer)[0];
                vtrace("DicomReader.readMetaInfo: metaInfoEnd = ", metaInfoEnd);
                self.readDataElement(loopFn);
            });
        } else {
            self.error("DicomReader.readMetaInfo: expected (0002,0000), got " +
                    dataElement.tag);
        }
    });
};

DicomReader.prototype.readFile = function (cont) {
    var self = this;
    self.readPreamble(function () {
        self.readDicomHeader(function () {
            self.readMetaInfo(function () {
                self.readDataset(cont);
            });
        });
    });
};

exports.DicomReader = DicomReader;

if (require.main === module) {
    var stream = fs.createReadStream(process.argv[2]);
    var dr = new DicomReader(stream);
    var t1 = new Date().getTime();
    dr.readFile(function () {
        var t2 = new Date().getTime();
        console.log("READ FILE DONE:", t2 - t1);
    });
}
