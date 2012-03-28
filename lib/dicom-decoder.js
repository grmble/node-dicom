/**
 *
 * Dicom Decoder
 *
 * This decodes a dicom file and translates it into various dicom events
 *
 */

var util = require('util');
var log4js = require('log4js');
var parsebuffer = require('./parsebuffer');
var vr = require('./vr');

var log = log4js.getLogger('dicom-decoder');

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
        if(dicm != 'DICM') {
            throw new Exception("Not a DICOM file:" + dicm);
        }
    });
};

DicomDecoder.prototype.decodeDataElement = function (callback) {
    var w16u = this.endianess.getUInt16;
    var w32u = this.endianess.getUInt32;
    var buffers = [];
    this.request(2, parsebuffer.setter(buffers));
    this.request(2, parsebuffer.setter(buffers));
    this.request(2, parsebuffer.setter(buffers, function () {
        var group = w16u(buffers[0]);
        var element = w16u(buffers[1]);
        var tag = (group << 16) ^ element;
        var vrStr = buffers[2].toString('ascii');
        var dataElement = new this.endianess[vrStr]();
        dataElement.tag = tag;
        var bytes = dataElement.valueLengthBytes(this.implicit);

        this.request(bytes, function (buffer) {
            var length;
            switch(bytes) {
                case 2:length = w16u(buffer);break;
                case 4:length = w32u(buffer);break;
                case 6:length = w32u(buffer.slice(2,6));break;
            }
            dataElement.length = length;

            this.request(length, function (rawValue) {
                dataElement.rawValue = rawValue;
                log.debug("decodeDataElement:", dataElement);
                callback(dataElement);
            }.bind(this));
        }.bind(this));
    }.bind(this)));

};

/**
 * Accumulator convenience method
 */
DicomDecoder.prototype.accumulate = function (dataElement) {
    this.accumulator[dataElement.tag] = dataElement;
}

/**
 * Decode the DICOM Meta Info
 *
 * This is the DICOM "file header" that contains the TransferSyntax
 * for the rest of the file.
 *
 */
DicomDecoder.prototype.decodeMetaInfo = function (callback) {
    this.decodeDataElement(function (dataElement) {
        if (dataElement.tag != 0x20000) {
            throw new Exception("Excpected 0x20000 to start metainfo:", dataElement)
        }
        var metainfoLength = dataElement.getValue(dataElement.rawValue, 0);
        log.info("decodeMetaInfo: metainfoLength:", metainfoLength);
        this.accumulate(dataElement);

        this.enterGroup(metainfoLength, function () {
            log.trace("decodeMetaInfo: end group", this.accumulator);
            callback();
        }.bind(this));

        var metainfoGroup = this.group();

        var metagroupHandler = function (dataElement) {
            log.trace("xxxx");
            this.accumulate(dataElement);
            if (this.group() === metainfoGroup) {
                this.decodeDataElement(metagroupHandler);
            }
        }.bind(this);
        if (this.group() === metainfoGroup) {
            log.trace("111");
            this.decodeDataElement(metagroupHandler);
        }
    }.bind(this));
};

exports.DicomDecoder = DicomDecoder;

if(require.main === module) {
    var DICOM_INPUT = "/opt/share/TESTDATA/agostini_giacomo/1B3D1BD1/15C540E7/95750D3B";
    var decoder = new DicomDecoder(require('fs').createReadStream(DICOM_INPUT));

    decoder.decodePreamble();
    decoder.decodeDicomPrefix();
    decoder.decodeMetaInfo(function() {
        log.debug("DecodeMetaInfo callback:", arguments);
    });
}