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
    uid = require('./uid'),
    log = log4js.getLogger('dicom-decoder'),
    verbose = true;

function DicomDecoder(stream, ts) {
    parsebuffer.ParseBuffer.call(this, stream);

    // the transfer syntax
    this.ts = ts || uid.ts.ExplicitVRLittleEndian;

    // accumulator for data elements
    this.accumulator = {};

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
        endianess = self.ts.endianess,
        w16u = endianess.getUInt16,
        w32u = endianess.getUInt32,
        buffers = [];
    self.request(2, parsebuffer.setter(buffers));
    self.request(2, parsebuffer.setter(buffers));
    self.request(2, parsebuffer.setter(buffers, function () {
        var group, element, tag, vrStr, VRConst, dataElement, bytes, length;
        group = w16u(buffers[0]);
        element = w16u(buffers[1]);
        tag = printf("(%04X,%04X)", group, element);
        vrStr = buffers[2].toString('ascii');
        VRConst = endianess[vrStr];
        if (!VRConst) {
            self.onError(new Error("No VR for:" + vrStr));
        }

        dataElement = new VRConst();
        dataElement.tag = tag;
        bytes = self.ts.valueLengthBytes(dataElement);

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
                log.trace("dataElement.length", length);
            }
            dataElement.length = length;

            self.request(length, function (rawValue) {
                dataElement.rawValue = rawValue;
                if (verbose) {
                    log.trace("RAWVALUE:", rawValue);
                };
                log.debug("decodeDataElement:", dataElement);
                log.debug("decodeDataElement:", dataElement.niceStr());
                callback(dataElement);
            });
        });
    }));
};

/**
 * Accumulator convenience method
 */
DicomDecoder.prototype.accumulate = function (dataElement) {
    this.accumulator[dataElement.tag] = dataElement;
};

/**
 * Decode the DICOM Meta Info
 *
 * This is the DICOM "file header" that contains the TransferSyntax
 * for the rest of the file.
 *
 */
DicomDecoder.prototype.decodeMetaInfo = function (callback) {
    var self = this;
    self.decodeDataElement(function (dataElement) {
		var metainfoLength, metainfoGroup, metagroupHandler;
        if (dataElement.tag !== 0x20000) {
            self.onError("Excpected 0x20000 to start metainfo:" + dataElement);
        }
        metainfoLength = dataElement.getValue(dataElement.rawValue, 0);
        log.info("decodeMetaInfo: metainfoLength:", metainfoLength);
        self.accumulate(dataElement);

        metainfoGroup = self.enterGroup(metainfoLength, function () {
            log.trace("decodeMetaInfo: end group", metainfoGroup.active);
            callback();
        });

        metagroupHandler = function (dataElement) {
            self.accumulate(dataElement);
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
    var self = this;
    if (!self.eof) {
        self.decodeDataElement(self.decode.bind(self));
    }
    callback();
};

exports.DicomDecoder = DicomDecoder;

if (require.main === module) {
    var DICOM_INPUT = "/opt/share/TESTDATA/agostini_giacomo/1B3D1BD1/15C540E7/95750D3B";
    var stream = require('fs').createReadStream(DICOM_INPUT);
    var decoder = new DicomDecoder(stream);

    decoder.decodePreamble();
    decoder.decodeDicomPrefix();
    decoder.decodeMetaInfo(function () {
        log.debug("DecodeMetaInfo callback:", arguments);
        decoder.decode(function () {
            log.debug("Decoder done");
        });
    });
}
