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
    parsebuffer = require('./parsebuffer'),
    vr = require('./vr'),
    uids = require('./uids'),
    tags = require('./tags'),
    log = log4js.getLogger('dicom-decoder'),
    verbose = true,


    unlimitedLength = Math.pow(2, 32) - 1;

// log4js.configure("debug-log4js.json");

function DicomDecoder(stream, ts) {
    parsebuffer.ParseBuffer.call(this, stream);

    // the transfer syntax
    this.ts = ts || uids.ts.ExplicitVRLittleEndian;

    // the next transfer syntax, will be switched to
    // at end of decodeMetaInfo
    this.nextTransferSyntax = undefined;
}
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

/**
 * Decode a single DataElement
 *
 */
DicomDecoder.prototype.decodeDataElement = function (callback) {
    var self = this,
        endianess = self.ts.endianess(),
        w16u = endianess.getUInt16,
        w32u = endianess.getUInt32,
        buffers = [];
    self.request(2, parsebuffer.setter(buffers));
    self.request(2, parsebuffer.setter(buffers, function () {
        var group = w16u(buffers[0]),
            element = w16u(buffers[1]),
            tag = printf("(%04X,%04X)", group, element),
            vrStr;

        function vrHandler() {
            var VRConst, dataElement, bytes, length;
            if (vrStr === undefined) {
                vrStr = buffers[2].toString('ascii');
            }
            VRConst = endianess[vrStr];
            if (tag === tags.Item.tag) {
                log.trace("xxxxxxxx");
                dataElement = {tag: tag};
                bytes = 4;
            } else if (!VRConst) {
                self.onError(new Error("No VR for:" + vrStr));
            } else {
                dataElement = new VRConst();
                dataElement.tag = tag;
                bytes = self.ts.valueLengthBytes(dataElement);
            }

            if (verbose) {
                log.trace("tag/vrStr/bytesLength:", tag, vrStr, bytes);
            }

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
                if (verbose) {
                    dataElement.length = length;
                    log.trace("dataElement with length", dataElement);
                }

                if (vrStr === 'SQ') {
                    if (length === unlimitedLength) {
                        log.debug("Unlimited SQ:", dataElement.parsedObj());
                        self.enterGroup(function () {
                            log.debug("End of unlimited SQ:", dataElement.parsedObj());
                        });
                    } else {
                        log.debug("Limited SQ:", dataElement.parsedObj());
                        self.enterGroup(length, function () {
                            log.debug("End of limited SQ:", dataElement.parsedObj());
                        });
                    }
                    callback(dataElement);
                } else if (tag === tags.Item.tag) {
                    log.trace("xxxxxxxx");
                    if (length === unlimitedLength) {
                        log.debug("Unlimited Item:", dataElement);
                        self.enterGroup(function () {
                            log.debug("End of unlimited Item:", dataElement);
                        });
                    } else {
                        log.debug("Limited Item:", dataElement);
                        self.enterGroup(length, function () {
                            log.debug("End of limited Item:", dataElement);
                        });
                    }
                    callback(dataElement);
                } else {
                    self.request(length, function (rawValue) {
                        dataElement.rawValue = rawValue;
                        if (verbose && log.isDebugEnabled()) {
                            log.debug("decodeDataElement:", dataElement.parsedObj());
                        }
                        callback(dataElement);
                    });
                }
            });
        }

        if (!self.ts.explicit || tag === tags.Item.tag) {
            // Item is always followed by 4 bytes length, no VR
            vrStr = tags.tag(tag).vr;
            if (verbose) {
                log.trace("decodeDataElement: implicit VR:", tag, vrStr);
            }
            vrHandler();
        } else {
            self.request(2, parsebuffer.setter(buffers, vrHandler));
        }
    }));
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
        transferSyntaxUIDTag = tags.TransferSyntaxUID.tag;

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
        elementCallback = function () {
            if (!self.eof) {
                self.decodeDataElement(elementCallback);
            } else {
                callback();
            }
        };
    if (!self.eof) {
        self.decodeDataElement(elementCallback);
    } else {
        callback();
    }
};

exports.DicomDecoder = DicomDecoder;

if (require.main === module) {
    var DICOM_INPUT = "/opt/share/TESTDATA/agostini_giacomo/1B3D1BD1/15C540E7/95750D3B";
    var stream = require('fs').createReadStream(DICOM_INPUT);
    var decoder = new DicomDecoder(stream),
        t1,
        t2;


    decoder.decodePreamble();
    decoder.decodeDicomPrefix();

    t1 = new Date().getTime();
    decoder.decodeMetaInfo(function () {
        t2 = new Date().getTime();
        log.debug("DecodeMetaInfo done in", t2 - t1);
        decoder.decode(function () {
            log.debug("Decoder done");
        });
    });
}
