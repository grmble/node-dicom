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
	parsebuffer = require('./parsebuffer'),
	vr = require('./vr'),
	log = log4js.getLogger('dicom-decoder');

function DicomDecoder(stream) {
    parsebuffer.ParseBuffer.call(this, stream);

    // the endianess of current TS
    this.endianess = vr.LE;
    // implicitness of current TS
    this.implicit = false;
    // for switching transferSyntax
    this.nextTransferSyntax = null;
    // flag for metainfo reading
    this.metaInfoDone = false;
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
    this.request(4, function (buffer) {
        var dicm = buffer.toString('ascii');
        if (dicm !== 'DICM') {
            throw new Error("Not a DICOM file:" + dicm);
        }
    });
};

/**
 * Decode a single DataElement
 *
 */
DicomDecoder.prototype.decodeDataElement = function (callback) {
    /*jslint bitwise: true, white: true */
    var self = this,
        w16u = self.endianess.getUInt16,
        w32u = self.endianess.getUInt32,
        buffers = [],
        group, element, tag, vrStr, dataElement, bytes, length;
    self.request(2, parsebuffer.setter(buffers));
    self.request(2, parsebuffer.setter(buffers));
    self.request(2, parsebuffer.setter(buffers, function () {
        group = w16u(buffers[0]);
        element = w16u(buffers[1]);
        tag = (group << 16) ^ element;
        vrStr = buffers[2].toString('ascii');
        dataElement = new self.endianess[vrStr]();
        dataElement.tag = tag;
        bytes = dataElement.valueLengthBytes(self.implicit);

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
            }
            dataElement.length = length;

            self.request(length, function (rawValue) {
                dataElement.rawValue = rawValue;
                log.debug("RAWVALUE:", rawValue);
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
    this.decodeDataElement(function (dataElement) {
		var metainfoLength, metainfoGroup, metagroupHandler;
        if (dataElement.tag !== 0x20000) {
            throw new Error("Excpected 0x20000 to start metainfo:", dataElement);
        }
        metainfoLength = dataElement.getValue(dataElement.rawValue, 0);
        log.info("decodeMetaInfo: metainfoLength:", metainfoLength);
        this.accumulate(dataElement);

        metainfoGroup = this.enterGroup(metainfoLength, function () {
            log.trace("decodeMetaInfo: end group", metainfoGroup.active);
            callback();
        }.bind(this));

        metagroupHandler = function (dataElement) {
            this.accumulate(dataElement);
            if (metainfoGroup.active) {
                this.decodeDataElement(metagroupHandler);
            }
        }.bind(this);
        if (metainfoGroup.active) {
            this.decodeDataElement(metagroupHandler);
        }
    }.bind(this));
};

exports.DicomDecoder = DicomDecoder;

if (require.main === module) {
    var DICOM_INPUT = "/opt/share/TESTDATA/agostini_giacomo/1B3D1BD1/15C540E7/95750D3B";
    var decoder = new DicomDecoder(require('fs').createReadStream(DICOM_INPUT));

    decoder.decodePreamble();
    decoder.decodeDicomPrefix();
    decoder.decodeMetaInfo(function () {
        log.debug("DecodeMetaInfo callback:", arguments);
    });
}
