/**
 *
 * Dicom Value Representations
 *
 */

var util = require('util');
var helper = require('./helper')

var ENDIAN_VRS = ['UL', 'OW', 'OF'];
var NON_ENDIAN_VRS = ['OB', 'SQ', 'UN', 'UT', 'UI', 'SH', 'CS', 'DA', 'TM'
                            , 'LO', 'ST', 'PN'];
var SIX_BYTE_VRS = ['OB', 'OW', 'OF', 'SQ', 'UN', 'UT'];

/**
 * Little Endian mixin
 */

function LittleEndianMixin () {
}

LittleEndianMixin.prototype.littleEndian = true;

LittleEndianMixin.prototype.getUInt32 = function (buffer, idx) {
    if (idx === undefined) {
        idx = 0;
    }
    return buffer.readUInt32LE(idx*4, true);
};

LittleEndianMixin.prototype.getUInt16 = function (buffer, idx) {
    if (idx === undefined) {
        idx = 0;
    }
    return buffer.readUInt16LE(idx*2, true);
};

LittleEndianMixin.prototype.getFloat32 = function (buffer, idx) {
    if (idx === undefined) {
        idx = 0;
    }
    return buffer.readFloatLE(idx*4, true);
};

/**
 * Big Endian mixin
 */
function BigEndianMixin () {
}

BigEndianMixin.prototype.littleEndian = false;

BigEndianMixin.prototype.getUInt32 = function (buffer, idx) {
    return buffer.readUInt32BE(idx*4, true);
};

BigEndianMixin.prototype.getUInt16 = function (buffer, idx) {
    return buffer.readUInt16BE(idx*2, true);
};

BigEndianMixin.prototype.getFloat32 = function (buffer, idx) {
    return buffer.readFloatBE(idx*4, true);
};


/**
 *
 *
 *
 * Base classes without endianess
 *
 *
 *
 *
 *
 *
 */


var DICOM = { 
    LE: function () {},
    BE: function() {}
};

/**
 *
 * VR: Base for all VRs
 *
 *
 *
 */
DICOM.VR = function () {};
DICOM.VR.prototype.valueLengthBytes = function (implicit) {
    return implicit ? 4 : this.explicitValueLengthBytes;
};
DICOM.VR.prototype.explicitValueLengthBytes = 2;

/**
 * FixedLength: Value Representation some kind of fixed length
 *
 * defaults to 4 bytes length ...
 */
DICOM.FixedLength = function () {};
util.inherits(DICOM.FixedLength, DICOM.VR);
DICOM.FixedLength.prototype.valueLength = 4;
DICOM.FixedLength.prototype.vm = function (buffer) {
    return buffer.length / this.valueLength;
};
DICOM.FixedLength.prototype.decode = function (buffer) {
    var count = this.vm(buffer)
        , acc = new Array(count)
        , i;
    for(i = 0; i < count; i++) {
        acc[i] = this.getValue(buffer, i);
    }
    return acc;
};


/**
 * Stringish: Value Representation in some kind of string
 */
DICOM.Stringish = function () {};
util.inherits(DICOM.Stringish, DICOM.VR);
DICOM.Stringish.prototype.splitRe = /\\/;
DICOM.Stringish.prototype.decode = function (buffer) {
    return buffer.toString('binary').split(this.splitRe);
};


/**
 * UL: 32 bit unsigned
 */
DICOM.UL = function () {this.vr='UL'};
util.inherits(DICOM.UL, DICOM.FixedLength);

DICOM.UL.prototype.getValue = function (buffer, idx) {
    return this.getUInt32(buffer, idx);
};

/**
 * OB:  bytes
 */
DICOM.OB = function () {this.vr='OB'};
util.inherits(DICOM.OB, DICOM.VR);
DICOM.OB.prototype.decode = function (buffer) {
    return [buffer];
};

/**
 * OW: 16 bit words
 */
DICOM.OW = function () {this.vr='OW'};
util.inherits(DICOM.OW, DICOM.OB);
// XXX: byteswap if bigendian!

/**
 * OF: 32 bit floats
 */
DICOM.OF = function () {this.vr='OF'};
util.inherits(DICOM.OF, DICOM.FixedLength);
DICOM.OF.prototype.getValue = function (buffer, idx) {
    return this.getFloat32(buffer, idx);
};

/**
 * SQ: A sequence of subordinate datasets
 */
DICOM.SQ = function () {this.vr='SQ'};
util.inherits(DICOM.SQ, DICOM.VR);

/**
 * UN: Like OB, but unknown
 */
DICOM.UN = function () {this.vr='UN'};
util.inherits(DICOM.UN, DICOM.OB);

/**
 * UT: Unlimited text.  String, may contain no backslashes
 */
DICOM.UT = function () {this.vr='UT'};
util.inherits(DICOM.UT, DICOM.VR);
DICOM.UT.prototype.decode = function (buffer) {
    return [ buffer.toString('binary') ];
};


/**
 * UI: UID String, 64 bytes max, 0 padded to even length
 */
DICOM.UI = function () {this.vr='UI'};
util.inherits(DICOM.UI, DICOM.Stringish);


/**
 * SH: Short String, 16 bytes max, backslash as separator between multiple values
 */
DICOM.SH = function () {this.vr='SH'};
util.inherits(DICOM.SH, DICOM.Stringish);

/**
 * LO: Long String, 64 bytes max, backslash as separator between multiple values
 */
DICOM.LO = function () {this.vr='LO'};
util.inherits(DICOM.SH, DICOM.Stringish);

/**
 * CS: Code String, leading/tailing spaces insignificant.
 * only uppercase, numbers, space and underscore allowed
 */
DICOM.CS = function () {this.vr='CS'};
util.inherits(DICOM.CS, DICOM.Stringish);


/**
 * DA: Date of the form YYYYMMDD, may also be YYYYMMDD-
 *  in range matches
 */
DICOM.DA = function () {this.vr='DA'};
util.inherits(DICOM.DA, DICOM.Stringish);


/**
 * TM: Time HHMMSS.FFFFFF
 */
DICOM.TM = function () {this.vr='TM'};
util.inherits(DICOM.TM, DICOM.Stringish);


/**
 * ST: Short Text, 1024 bytes maximum, no backslashes == only one value ever
 */
DICOM.ST = function () {this.vr='ST'};
util.inherits(DICOM.ST, DICOM.UT);

/**
 * PN: Person name
 */
DICOM.PN = function () {this.vr='PN'};
util.inherits(DICOM.PN, DICOM.Stringish);


/**
 *
 * override explicit value length bytes
 */
SIX_BYTE_VRS.forEach(function (klassName) {
    DICOM[klassName].prototype.explicitValueLengthBytes = 6;
});

/**
 *
 *
 *
 *
 * ENDIANESS SPECIFIC CLASSES
 *
 *
 */

ENDIAN_VRS.forEach(function (klassName) {
    DICOM.LE[klassName] = function () { DICOM[klassName].call(this) };
    util.inherits(DICOM.LE[klassName], DICOM[klassName]);
    helper.mixin(DICOM.LE[klassName], LittleEndianMixin);
    helper.mixin(DICOM.LE[klassName], LittleEndianMixin, 'littleEndian');

    DICOM.BE[klassName] = function () { DICOM[klassName].call(this) };
    util.inherits(DICOM.BE[klassName], DICOM[klassName]);
    helper.mixin(DICOM.BE[klassName], BigEndianMixin);
    helper.mixin(DICOM.BE[klassName], BigEndianMixin, 'littleEndian');
});


// also put in the vrs without endianess specific encoding
NON_ENDIAN_VRS.forEach(function (klassName) {
    DICOM.LE[klassName] = DICOM[klassName];
    DICOM.BE[klassName] = DICOM[klassName];
});

// mix it into the LE/BE constructor as well
helper.mixin(DICOM.LE, LittleEndianMixin);
helper.mixin(DICOM.LE, LittleEndianMixin, 'littleEndian');
helper.mixin(DICOM.BE, BigEndianMixin);
helper.mixin(DICOM.BE, BigEndianMixin, 'littleEndian');

exports.LE = new DICOM.LE();
exports.BE = new DICOM.BE();

/**
 *
 * copy the constructor functions
 * 
 */
[].concat(ENDIAN_VRS, NON_ENDIAN_VRS).forEach(function (klassName) {
    exports.LE[klassName] = DICOM.LE[klassName];
    exports.BE[klassName] = DICOM.BE[klassName];
});
