"use strict";

/*jslint nomen: true */

var util = require('util'),
    fs = require('fs'),
    path = require('path'),
    printf = require('printf'),
    ReadBuffer = require('./readbuffer').ReadBuffer,
    delay = require('./delay'),
    uids = require('./uids'),
    tags = require('./tags'),
    vr = require('./vr');


var verbose = true;
var vtrace = delay.logFn(verbose, console.log);

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
        var endedElement, topNested, endOffset,
            nested = self.nested;
        if (dataElement.nesting) {
            vtrace("DicomReader.readDataELement nesting:", dataElement.nestedLength);
            nested.push(dataElement);
            emitAndCont();
        } else if (dataElement.endsNesting) {
            vtrace("DicomReader.readDataElement endsNesting", dataElement.tag);
            endedElement = nested.pop();
            if (endedElement.nestedLength) {
                self.error("Internal error, explicit end tag ends limited sq/item: " +
                        endedElement + " ended by " + dataElement);
            } else {
                emitAndCont();
            }
        } else {
            topNested = nested[nested.length - 1];
            if (topNested && topNested.nestedLength) {
                endOffset = topNested.offset +  topNested.nestedLength;
                if (dataElement.offset > endOffset) {
                    vtrace("DicomReader.readDataElement: end of limited nesting:",
                            topNested);
                    nested.pop();
                }
            }
            emitAndCont();
        }
    };

    emitAndCont = function () {
        vtrace("DicomReader.readDataElement: emitting:",
                delay.delay(dataElement, dataElement.toString));
        self.emit('element', dataElement);
        cont(dataElement);
    };

    self.read(8, buff8CB);
};

DicomReader.prototype.streamDataElementValue = function (dataElement, cont) {
    this.streamData(dataElement.valueLength, cont);
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
                vtrace("EOF, not remaining nested elements");
                cont();
            } else {
                self.error("EOF with pending nested elements:",
                        delay(self.nested[self.nested.length - 1]));
            }
        } else {
            self.nextTick(self.readDataElement, streamer);
        }
    };

    streamer = function (dataElement) {
        if (dataElement.valueLength) {
            self.streamDataElementValue(dataElement, eofCaller);
        } else {
            eofCaller();
        }
    };

    eofCaller();
};

if (require.main === module) {
    var stream = fs.createReadStream(path.join(__dirname, "../test/patient.blob"));
    var dr = new DicomReader(stream);
    dr.readDataset(console.log);
}
