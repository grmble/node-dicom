"use strict";

/**
 *
 * Dicom Decoder
 *
 * This decodes a dicom file and translates it into various dicom events
 *
 */

var util = require('util'),
    log4js = require('log4js'),
    printf = require('printf'),
    helper = require('./helper'),
    parsebuffer = require('./parsebuffer'),
    vr = require('./vr'),
    uids = require('./uids'),
    tags = require('./tags'),
    log = log4js.getLogger('dicom-decoder'),
    verbose = false,


    unlimitedLength = Math.pow(2, 32) - 1;

// log4js.configure("debug-log4js.json");

var DicomDecoder = function (stream, ts) {
    parsebuffer.ParseBuffer.call(this, stream);

    // start event has been emitted
    this.startEmitted = false;

    // the transfer syntax
    this.ts = ts || uids.ts.ExplicitVRLittleEndian;

    // the next transfer syntax, will be switched to
    // at end of decodeMetaInfo
    this.nextTransferSyntax = undefined;
};
util.inherits(DicomDecoder, parsebuffer.ParseBuffer);

/**
 * Decode the DICOM preamble.
 *
 * This just requests the first 128 bytes.
 */
DicomDecoder.prototype.decodePreamble = function () {
    this.request(128, function () {});
};

/**
 * Decode the DICOM prefix.
 *
 * These are 4 bytes that should be "DICM" in ascii
 */
DicomDecoder.prototype.decodeDicomPrefix = function () {
    var self = this;
    this.request(4, function (buffer) {
        var dicm = buffer.toString('ascii');
        if (dicm !== 'DICM') {
            self.onError("Not a DICOM file:" + dicm);
        }
    });
};

// dataelements without values that need special handling
var noValueTags = {
    "(FFFE,E000)": true, // Item
    "(FFFE,E00D)": true, // ItemDelimitationItem
    "(FFFE,E0DD)": true, // SequenceDelimitationItem
};
var encapsulatedTags = {
    "(FFFE,E000)": true, // Item
    "(FFFE,E00D)": true, // ItemDelimitationItem
};
var endEncapsTags = {
    "(FFFE,E0DD)": true, // SequenceDelimitationItem
};
// item tags
var itemTags = {
    "(FFFE,E000)": true, // Item
    "(FFFE,E00D)": true, // ItemDelimitationItem
};

var verboseTrace = function () {
    if (verbose && log.isTraceEnabled()) {
        log.trace.apply(log, arguments);
    }
};

var traceParsedObj = function (msg, dataElement) {
    if (verbose && log.isTraceEnabled()) {
        var what = dataElement;
        if (what && what.parsedObj) {
            what = what.parsedObj();
        }
        log.trace(msg, what);
    }
};

/**
 * Decode a single DataElement
 *
 */
DicomDecoder.prototype.decodeDataElement = function (callback) {
    var self = this,
        endianess = self.ts.endianess(),
        w16u = endianess.getUInt16,
        w32u = endianess.getUInt32,
        offset = self.streamPosition,
        buffers = [];
    self.request(2, parsebuffer.setter(buffers));
    self.request(2, parsebuffer.setter(buffers, function () {
        // trigger one more callback at EOF
        if (!buffers[0] && !buffers[1] && self.isStopped()) {
            callback();
            return;
        }
        var group = w16u(buffers[0]),
            element = w16u(buffers[1]),
            tag = printf("(%04X,%04X)", group, element),
            vrStr;

        function vrHandler() {
            var VRConst, dataElement, bytes, length, mustEnter;
            if (vrStr === undefined) {
                vrStr = buffers[2].toString('ascii');
            }
            VRConst = endianess[vrStr];
            if (!VRConst) {
                self.onError(new Error("No VR for:" + vrStr));
            } else {
                dataElement = new VRConst();
                dataElement.tag = tag;
                dataElement.offset = offset;
                bytes = self.ts.valueLengthBytes(dataElement);
            }

            verboseTrace("tag/vrStr/bytesLength:", tag, vrStr, bytes);

            self.request(bytes, function (buffer) {
                switch (bytes) {
                case 2:
                    length = w16u(buffer);
                    break;
                case 4:
                    length = w32u(buffer);
                    break;
                case 6:
                    length = w32u(buffer.slice(2, 6));
                    break;
                default:
                    self.onError("huh? unexpected fallthrough");
                }
                dataElement.length = length;
                verboseTrace("dataElement with length", dataElement);

                // the item in an encapsulated pixel data thing
                // contains the actual pixeldata
                if (self.group() && self.group().encapsulated) {
                    if (encapsulatedTags[tag]) {
                        traceParsedObj("decodeDataElement Encapsulated:", dataElement);
                        self.requestStream(length, function (buffer) {
                            traceParsedObj("decodeDataElement streamed data, length", buffer.length);
                        }, function () {
                            traceParsedObj("decodeDataElement encapsulated done");
                            callback(dataElement);
                        });
                    } else if (endEncapsTags[tag]) {
                        self.exitGroup();
                        verboseTrace("end of encaps group");
                        callback(dataElement);
                    } else {
                        self.onError(new Error("only item and delimitation items allowed"));
                    }
                } else if (vrStr === 'SQ' || noValueTags[tag]) {
                    mustEnter = (vrStr === 'SQ' || tag === tags.Item);
                    // vrStr is either SQ or NoValue or Delimitation/Item tags
                    if (length === unlimitedLength &&  mustEnter) {
                        self.enterGroup().type = vrStr;
                    } else if (mustEnter) {
                        self.enterGroup(length, function (theGroup) {
                            traceParsedObj("exiting limited group", theGroup);
                        }).type = vrStr;
                    } else {
                        (function () {
                            /*jslint white: true */
                            var theGroup = self.group();
                            if (theGroup && 
                                ((theGroup.type === 'SQ' && 
                                  dataElement.tag === tags.SequenceDelimitationItem) ||
                                 itemTags[tag])) {
                                self.exitGroup();
                            } else {
                                self.onError(new Error(util.format("Attempt to terminate ", 
                                            theGroup, "by", dataElement)));
                            }
                        }());
                    }
                    traceParsedObj("sequence related data elem:", dataElement);
                    callback(dataElement);
                } else if (length === unlimitedLength) {
                    self.enterGroup().encapsulated = true;
                    traceParsedObj("decodateDataElement encapsulated:", dataElement);
                    callback(dataElement);
                } else {
                    self.request(length, function (rawValue) {
                        dataElement.rawValue = rawValue;
                        traceParsedObj("decodeDataElement:", dataElement);
                        self.doEmit('element', dataElement);
                        callback(dataElement);
                    });
                }
            });
        }

        if (!self.ts.explicit) {
            vrStr = tags.tag(tag).vr;
            verboseTrace("decodeDataElement: implicit VR:", tag, vrStr);
        } else if (noValueTags[tag]) {
            vrStr = 'NoValue';
            verboseTrace("decodeDataElement: noValue:", tag, vrStr);
            vrHandler();
        } else {
            self.request(2, parsebuffer.setter(buffers, vrHandler));
        }
    }));
};


DicomDecoder.prototype.doEmit = function (evt, obj) {
    if (!this.startEmitted) {
        this.emit('start');
        this.startEmitted = true;
    }
    this.emit(evt, obj);
};

/**
 * Decode the DICOM Meta Info
 *
 * This is the DICOM "file header" that contains the TransferSyntax
 * for the rest of the file.
 *
 */
DicomDecoder.prototype.decodeMetaInfo = function (callback) {
    var self = this,
        transferSyntaxUIDTag = tags.TransferSyntaxUID;

    self.decodeDataElement(function (dataElement) {
		var metainfoLength, metainfoGroup, metagroupHandler;
        if (dataElement.tag !== '(0002,0000)') {
            self.onError("Excpected 0x20000 to start metainfo:" + dataElement.tag);
        }
        metainfoLength = dataElement.getValue(0);
        log.debug("decodeMetaInfo: metainfoLength:", metainfoLength);

        metainfoGroup = self.enterGroup(metainfoLength, function () {
            log.debug("end of meta info, switching transfer syntax to",
                self.nextTransferSyntax);
            self.ts = self.nextTransferSyntax;
            self.nextTransferSyntax = undefined;
            callback();
        });

        metagroupHandler = function (dataElement) {
            if (dataElement.tag === transferSyntaxUIDTag) {
                self.nextTransferSyntax = uids.uid(dataElement.decode()[0]);
                log.debug("found next transfer syntax:", self.nextTransferSyntax);
            }
            if (metainfoGroup.active) {
                self.decodeDataElement(metagroupHandler);
            }
        };
        if (metainfoGroup.active) {
            self.decodeDataElement(metagroupHandler);
        }
    });
};

/**
 * Decode the DICOM data
 *
 * This is the actual, real DICOM data.
 *
 */
DicomDecoder.prototype.decode = function (callback) {
    var self = this,
        endFn = function () {
            self.emit('end');
            callback();
        },
        elementCallback = function () {
            if (!self.eof) {
                self.decodeDataElement(elementCallback);
            }
            if (self.eof) {
                endFn();
            }
        };
    if (!self.eof) {
        self.decodeDataElement(elementCallback);
    }
    if (self.eof) {
        endFn();
    }
};

exports.DicomDecoder = DicomDecoder;

