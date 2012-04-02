"use strict";
/**
 *
 * Dicom Value Representations
 *
 */

var util = require('util'),
    helper = require('./helper'),
    assert = require('assert'),
    tags = require('./tags'),
    log4js = require('log4js'),
    log = log4js.getLogger('vr'),
    verbose = false;

var ENDIAN_VRS = ['UL', 'US', 'OW', 'OF'];
var NON_ENDIAN_VRS = ['OB', 'SQ', 'UN', 'UT', 'UI', 'SH', 'CS', 'DS', 'IS',
    'DA', 'TM', 'LO', 'ST', 'LT', 'PN', 'AS', 'NoValue'];
var SIX_BYTE_VRS = ['OB', 'OW', 'OF', 'SQ', 'UN', 'UT'];

/**
 * Little Endian mixin
 */

function LittleEndianMixin() {
}

LittleEndianMixin.prototype.littleEndian = true;

LittleEndianMixin.prototype.getUInt32 = function (buffer, idx) {
    if (idx === undefined) {
        idx = 0;
    }
    return buffer.readUInt32LE(idx * 4, true);
};

LittleEndianMixin.prototype.getUInt16 = function (buffer, idx) {
    if (idx === undefined) {
        idx = 0;
    }
    return buffer.readUInt16LE(idx * 2, true);
};

LittleEndianMixin.prototype.getFloat32 = function (buffer, idx) {
    if (idx === undefined) {
        idx = 0;
    }
    return buffer.readFloatLE(idx * 4, true);
};

/**
 * Big Endian mixin
 */
function BigEndianMixin() {
}

BigEndianMixin.prototype.littleEndian = false;

BigEndianMixin.prototype.getUInt32 = function (buffer, idx) {
    return buffer.readUInt32BE(idx * 4, true);
};

BigEndianMixin.prototype.getUInt16 = function (buffer, idx) {
    return buffer.readUInt16BE(idx * 2, true);
};

BigEndianMixin.prototype.getFloat32 = function (buffer, idx) {
    return buffer.readFloatBE(idx * 4, true);
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
    BE: function () {}
};

/**
 *
 * VR: Base for all VRs
 *
 *
 *
 */
DICOM.VR = function (obj) {
    var self = this;
    if (obj !== undefined) {
        helper.forKeys(obj, function (k, v) {
            self[k] = v;
        });
    }
};
DICOM.VR.prototype.explicitValueLengthBytes = 2;
DICOM.VR.prototype.implicitValueLengthBytes = 4;

// resolve tag name helper
var resolveTagName = function (tag) {
    var tagObj = tags.tag(tag);
    return tagObj && tagObj.name;
};

/**
 * A nice object with parsed values.
 *
 * Also has the name for the dicom tag for convenience.
 *
 */
DICOM.VR.prototype.parsedObj = function () {
    var obj = {
        tag: this.tag,
        vr: this.vr,
        offset: this.offset,
        name: resolveTagName(this.tag)
    };
    try {
        obj.values = this.decode();
    } catch (ex) {
        if (verbose) {
            log.trace("could not extract values:", this, ex);
        }
        obj.rawValue = this.rawValue;
    }
    return obj;
};

/**
 * FixedLength: Value Representation some kind of fixed length
 *
 * defaults to 4 bytes length ...
 */
DICOM.FixedLength = function () {
    DICOM.VR.apply(this, arguments);
};
util.inherits(DICOM.FixedLength, DICOM.VR);
DICOM.FixedLength.prototype.valueLength = 4;
DICOM.FixedLength.prototype.vm = function () {
    return this.rawValue.length / this.valueLength;
};
DICOM.FixedLength.prototype.decode = function () {
    var count = this.vm(),
        acc = [],
        i;
    for (i = 0; i < count; i += 1) {
        acc[i] = this.getValue(i);
    }
    return acc;
};


/**
 * Stringish: Value Representation in some kind of string
 */
DICOM.Stringish = function () {
    DICOM.VR.apply(this, arguments);
};
util.inherits(DICOM.Stringish, DICOM.VR);
DICOM.Stringish.prototype.trimValue = function (s) {
    return (s !== undefined) ? s.trim() : s;
};
DICOM.Stringish.prototype.splitRe = /\\/;
DICOM.Stringish.prototype.decode = function () {
    // XXX: String encodings other than binary!
    return this.rawValue.toString('binary').split(this.splitRe).map(this.trimValue);
};



/**
 * UL: 32 bit unsigned
 */
DICOM.UL = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'UL';
};
util.inherits(DICOM.UL, DICOM.FixedLength);

DICOM.UL.prototype.getValue = function (idx) {
    return this.getUInt32(this.rawValue, idx);
};

/**
 * US: 16 bit unsigned
 */
DICOM.US = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'US';
};
util.inherits(DICOM.US, DICOM.FixedLength);
DICOM.US.prototype.valueLength = 2;
DICOM.US.prototype.getValue = function (idx) {
    return this.getUInt16(this.rawValue, idx);
};

/**
 * OB:  bytes
 */
DICOM.OB = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'OB';
};
util.inherits(DICOM.OB, DICOM.VR);
DICOM.OB.prototype.decode = function () {
    return [this.rawValue];
};

/**
 * OW: 16 bit words
 */
DICOM.OW = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'OW';
};
util.inherits(DICOM.OW, DICOM.OB);
// XXX: byteswap if bigendian!

/**
 * OF: 32 bit floats
 */
DICOM.OF = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'OF';
};
util.inherits(DICOM.OF, DICOM.FixedLength);
DICOM.OF.prototype.getValue = function (idx) {
    return this.getFloat32(this.rawValue, idx);
};

/**
 * NoValue: a fake no-value vr
 *
 * this is because we have to model DataElements that do not
 * have values so to speak.
 *
 */
DICOM.NoValue = function () {
    DICOM.VR.apply(this, arguments);
};
util.inherits(DICOM.NoValue, DICOM.VR);
DICOM.NoValue.prototype.noValue = true;
// these always have 4 bytes
DICOM.NoValue.prototype.explicitValueLengthBytes = 4;

/**
 * SQ: A sequence of subordinate datasets
 */
DICOM.SQ = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'SQ';
};
util.inherits(DICOM.SQ, DICOM.VR);

/**
 * UN: Like OB, but unknown
 */
DICOM.UN = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'UN';
};
util.inherits(DICOM.UN, DICOM.OB);

/**
 * ST: Short Text, 1024 bytes maximum, no backslashes == only one value ever
 */
DICOM.ST = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'ST';
};
util.inherits(DICOM.ST, DICOM.VR);
DICOM.ST.prototype.decode = function () {
    return [ this.rawValue.toString('binary') ];
};

/**
 * AS: Age String, 4 bytes of the form 012Y, 003M, 002W, 001D
 */
DICOM.AS = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'AS';
};
util.inherits(DICOM.AS, DICOM.ST);


/**
 * LT: Long Text.  String, may contain no backslashes
 */
DICOM.LT = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'LT';
};
util.inherits(DICOM.LT, DICOM.ST);

/**
 * UT: Unlimited text.  String, may contain no backslashes
 */
DICOM.UT = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'UT';
};
util.inherits(DICOM.UT, DICOM.ST);


/**
 * UI: UID String, 64 bytes max, 0 padded to even length
 */
DICOM.UI = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'UI';
};
util.inherits(DICOM.UI, DICOM.Stringish);
DICOM.UI.prototype.trimValue = function (s) {
    if (s !== undefined) {
        return s.replace(/\u0000$/, '');
    }
};

/**
 * SH: Short String, 16 bytes max, backslash as separator between multiple values
 */
DICOM.SH = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'SH';
};
util.inherits(DICOM.SH, DICOM.Stringish);

/**
 * LO: Long String, 64 bytes max, backslash as separator between multiple values
 */
DICOM.LO = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'LO';
};
util.inherits(DICOM.LO, DICOM.Stringish);

/**
 * CS: Code String, leading/tailing spaces insignificant.
 * only uppercase, numbers, space and underscore allowed
 */
DICOM.CS = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'CS';
};
util.inherits(DICOM.CS, DICOM.Stringish);


/**
 * DS: Decimal String, contains digits, ., +, - and e.
 */
DICOM.DS = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'DS';
};
util.inherits(DICOM.DS, DICOM.Stringish);


/**
 * IS: Integer String, contains digits, +, -
 */
DICOM.IS = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'IS';
};
util.inherits(DICOM.IS, DICOM.Stringish);


/**
 * DA: Date of the form YYYYMMDD, may also be YYYYMMDD-
 *  in range matches
 */
DICOM.DA = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'DA';
};
util.inherits(DICOM.DA, DICOM.Stringish);


/**
 * TM: Time HHMMSS.FFFFFF
 */
DICOM.TM = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'TM';
};
util.inherits(DICOM.TM, DICOM.Stringish);


/**
 * PN: Person name
 */
DICOM.PN = function () {
    DICOM.VR.apply(this, arguments);
    this.vr = 'PN';
};
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
    DICOM.LE[klassName] = function () {
		DICOM[klassName].apply(this, arguments);
	};
    util.inherits(DICOM.LE[klassName], DICOM[klassName]);
    helper.mixin(DICOM.LE[klassName], LittleEndianMixin);
    helper.mixin(DICOM.LE[klassName], LittleEndianMixin, 'littleEndian');

    DICOM.BE[klassName] = function () {
		DICOM[klassName].apply(this, arguments);
	};
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
