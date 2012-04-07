"use strict";

/*jslint nomen: true */

var util = require('util'),
    printf = require('printf'),
    ReadBuffer = require('./readbuffer').ReadBuffer,
    delay = require('./delay'),
    uids = require('./uids'),
    tags = require('./tags'),
    vr = require('./vr');


var verbose = true;
var vtrace = delay.logFn(verbose, console.log);

var DicomReader = function (stream) {
    ReadBuffer.call(this, stream);
    this.ts = uids.ts.ExplicitVRLittleEndian;
};
util.inherits(DicomReader, ReadBuffer);

var tagsWithoutVR = {};
tagsWithoutVR[tags.Item] = true;
tagsWithoutVR[tags.ItemDelimitationItem] = true;
tagsWithoutVR[tags.SequenceDelimitationItem] = true;

DicomReader.prototype.readDataElement = function (cont) {
    var group, element, tag, vrStr, valueLengthBytes,
        VRConstructor, dataElement,
        self = this,
        endianess = self.ts.endianess(),
        offset = self.streamPosition,
        w16u = endianess.getUInt16,

        emitAndCont = function () {
            vtrace("DicomReader.readDataElement length=", dataElement.length);
            self.emit('element', dataElement);
            cont(dataElement);
        },

        buff4CB = function (buffer) {
            dataElement.length = endianess.getUInt32(buffer, 0);
            emitAndCont();
        },

        buff8CB = function (buffer) {
            group = w16u(buffer, 0);
            element = w16u(buffer, 1);
            tag = printf("(%04X,%04X)", group, element);
            vtrace("DicomReader.readDataElement: tag=", tag);

            if (!self.ts.explicit) {
                vrStr = tags.tag(tag).vr;
            } else if (tagsWithoutVR[tag]) {
                vrStr = 'NoValue';
            } else if (!tagsWithoutVR[tag]) {
                vrStr = buffer.slice(4, 6).toString();
            }
            vtrace("DicomReader.readDataElement: vrStr=", vrStr);

            VRConstructor = endianess[vrStr];
            if (!VRConstructor) {
                self.error("No VR for" + vrStr);
            } else {
                dataElement = new VRConstructor();
                dataElement.tag = tag;
                dataElement.offset = offset;
                valueLengthBytes = self.ts.valueLengthBytes(dataElement);
                vtrace("DicomReader.readDataElement: value length bytes:", valueLengthBytes);
                if (valueLengthBytes === 2) {
                    dataElement.length = w16u(buffer, 3);
                    emitAndCont();
                } else if (valueLengthBytes === 4) {
                    dataElement.length = endianess.getUInt32(buffer, 1);
                    emitAndCont();
                } else if (valueLengthBytes === 6) {
                    self.read(4, buff4CB);
                } else {
                    self.error("Huh? no valueLengthBytes for vr/ts");
                }
            }
        },

        eofCheck = function (eof) {
            if (eof) {
                vtrace("EOF");
                cont();
            } else {
                self.read(8, buff8CB);
            }
        };

    self.eof(eofCheck);
};


if (require.main === module) {
    // (0010,0010) PN x^y
    var buff = new Buffer([0x10, 0x00, 0x10, 0x00, 0x50, 0x4e, 0x03, 0x00, 0x78, 0x5e, 0x79]);
    var dr = new DicomReader();
    dr.onData(buff);
    dr.readDataElement(function (elem) {
        console.log("dataElement:", elem.parsedObj());
    });
}
