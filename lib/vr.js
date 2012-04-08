"use strict";
/*jslint nomen: true */

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
    'DA', 'TM', 'LO', 'ST', 'LT', 'PN', 'AS', 'NoVR'];
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
    self._rawValues = [];
};
DICOM.VR.prototype._unlimitedLength = Math.pow(2, 32) - 1;
DICOM.VR.prototype.explicitValueLengthBytes = 2;
DICOM.VR.prototype.implicitValueLengthBytes = 4;

/**
 * Get the parsed values.
 *
 */
DICOM.VR.prototype.values = function () {
    if (this._values === undefined) {
        this._values = this.getValues(this.rawValue);
    }
    return this._values;
};

/**
 * Get a parsed value.
 *
 */
DICOM.VR.prototype.value = function (idx) {
    if (idx === undefined) {
        idx = 0;
    }
    return this.values()[idx];
};


/**
 * Set the raw value and null the cached parse value.
 *
 */
DICOM.VR.prototype.setRawValue = function (raw) {
    this._values = undefined;
    this.rawValue = raw;
};

/**
 * Push a partial raw value.
 */
DICOM.VR.prototype.pushRaw = function (buffer) {
    this._rawValues.push(buffer);
};

/**
 * Combine the partial raws.
 *
 */
DICOM.VR.prototype.combineRaws = function () {
    this._values = undefined;

    var i, dst, buff,
        rawValues = this._rawValues,
        len = rawValues.length,
        bytes = 0,
        pos = 0;

    if (len === 0) {
        this._rawValues = undefined;
        this.rawValue = undefined;
        this._values = [];
        return;
    }

    for (i = 0; i < len; i += 1) {
        bytes += rawValues[i].length;
    }

    dst = new Buffer(bytes);

    for (i = 0; i < len; i += 1) {
        buff = rawValues[i];
        buff.copy(dst, pos, 0, buff.length);
        pos += buff.length;
    }

    this.rawValue = dst;
    this._rawValues = undefined;
};

/**
 * Set the data element length.
 *
 * This usually sets the valueLength, but for
 * nesting elements like SQ or Item, it sets the
 * nestedLength.
 */
DICOM.VR.prototype.setElementLength = function (len) {
    if (this.tag === tags.PixelData && len === this._unlimitedLength) {
        this.nestedLength = undefined;
        this.valueLength = undefined;
        this.unlimited = true;
        this.encapsulated = true;
    } else {
        this.nestedLength = undefined;
        this.valueLength = len;
    }
};

// resolve tag name helper
var resolveTagName = function (tag) {
    var tagObj = tags.tag(tag);
    return tagObj && tagObj.name;
};

/**
 * A nice object with parsed values.
 *
 */
DICOM.VR.prototype.toString = function () {
    if (this.tag && !this.name) {
        this.name = resolveTagName(this.tag);
    }
    return "<" + this.vr + ":" +
        util.inspect(this) + ">";
};

/**
 * FixedLength: Value Representation some kind of fixed length
 *
 * defaults to 4 bytes length ...
 */
DICOM.FixedLength = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.FixedLength, DICOM.VR);
DICOM.FixedLength.prototype.singleValueLength = 4;
DICOM.FixedLength.prototype.vm = function (rawValue) {
    return rawValue.length / this.singleValueLength;
};
DICOM.FixedLength.prototype.getValues = function (raw) {
    var count = this.vm(raw),
        acc = [],
        i;
    for (i = 0; i < count; i += 1) {
        acc[i] = this.getValue(raw, i);
    }
    return acc;
};


/**
 * Stringish: Value Representation in some kind of string
 */
DICOM.Stringish = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.Stringish, DICOM.VR);
DICOM.Stringish.prototype.trimValue = function (s) {
    return (s !== undefined) ? s.trim() : s;
};
DICOM.Stringish.prototype.splitRe = /\\/;
DICOM.Stringish.prototype.getValues = function (raw) {
    // XXX: String encodings other than binary!
    return raw.toString('binary').split(this.splitRe).map(this.trimValue);
};



/**
 * UL: 32 bit unsigned
 */
DICOM.UL = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.UL, DICOM.FixedLength);

DICOM.UL.prototype.vr = 'UL';
DICOM.UL.prototype.getValue = function (raw, idx) {
    return this.getUInt32(raw, idx);
};

/**
 * US: 16 bit unsigned
 */
DICOM.US = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.US, DICOM.FixedLength);
DICOM.US.prototype.vr = 'US';
DICOM.US.prototype.singleValueLength = 2;
DICOM.US.prototype.getValue = function (raw, idx) {
    return this.getUInt16(raw, idx);
};

/**
 * OB:  bytes
 */
DICOM.OB = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.OB, DICOM.VR);
DICOM.OB.prototype.vr = 'OB';
DICOM.OB.prototype.getValues = function (raw) {
    return [raw];
};

/**
 * OW: 16 bit words
 */
DICOM.OW = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.OW, DICOM.OB);
// XXX: byteswap if bigendian!
DICOM.OW.prototype.vr = 'OW';

/**
 * OF: 32 bit floats
 */
DICOM.OF = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.OF, DICOM.FixedLength);
DICOM.OF.prototype.vr = 'OF';
DICOM.OF.prototype.getValue = function (raw, idx) {
    return this.getFloat32(this.rawValue, idx);
};

/**
 * SQ: A sequence of subordinate datasets
 */
DICOM.SQ = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.SQ, DICOM.VR);

DICOM.SQ.prototype.vr = 'SQ';

DICOM.SQ.prototype.nesting = true;

DICOM.SQ.prototype.setElementLength = function (len) {
    this.valueLength = undefined;
    if (len === this._unlimitedLength) {
        this.nestedLength = undefined;
        this.unlimited = true;
    } else {
        this.nestedLength = len;
        this.unlimited = false;
    }
};

/**
 * NoVR: a fake no-value vr
 *
 * this is because we have to model DataElements that do not
 * have values so to speak.
 *
 */
DICOM.NoVR = function (obj) {
    DICOM.VR.call(this, obj);
    this.nesting = (this.tag === '(FFFE,E000)'); // only Item
    this.endsNesting = (this.tag !== '(FFFE,E000)'); // the others
};
util.inherits(DICOM.NoVR, DICOM.SQ);
DICOM.NoVR.prototype.vr = 'NoVR';
DICOM.NoVR.prototype.noVR = true;
// these always have 4 bytes
DICOM.NoVR.prototype.explicitValueLengthBytes = 4;

/**
 * UN: Like OB, but unknown
 */
DICOM.UN = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.UN, DICOM.OB);
DICOM.UN.prototype.vr = 'UN';

/**
 * ST: Short Text, 1024 bytes maximum, no backslashes == only one value ever
 */
DICOM.ST = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.ST, DICOM.VR);
DICOM.ST.prototype.vr = 'ST';
DICOM.ST.prototype.getValues = function (raw) {
    return [ raw.toString('binary') ];
};

/**
 * AS: Age String, 4 bytes of the form 012Y, 003M, 002W, 001D
 */
DICOM.AS = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.AS, DICOM.ST);
DICOM.AS.prototype.vr = 'AS';


/**
 * LT: Long Text.  String, may contain no backslashes
 */
DICOM.LT = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.LT, DICOM.ST);
DICOM.LT.prototype.vr = 'LT';

/**
 * UT: Unlimited text.  String, may contain no backslashes
 */
DICOM.UT = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.UT, DICOM.ST);
DICOM.UT.prototype.vr = 'UT';

/**
 * UI: UID String, 64 bytes max, 0 padded to even length
 */
DICOM.UI = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.UI, DICOM.Stringish);
DICOM.UI.prototype.vr = 'UI';
DICOM.UI.prototype.trimValue = function (s) {
    if (s !== undefined) {
        return s.replace(/\u0000$/, '');
    }
};

/**
 * SH: Short String, 16 bytes max, backslash as separator between multiple values
 */
DICOM.SH = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.SH, DICOM.Stringish);
DICOM.SH.prototype.vr = 'SH';

/**
 * LO: Long String, 64 bytes max, backslash as separator between multiple values
 */
DICOM.LO = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.LO, DICOM.Stringish);
DICOM.LO.prototype.vr = 'LO';

/**
 * CS: Code String, leading/tailing spaces insignificant.
 * only uppercase, numbers, space and underscore allowed
 */
DICOM.CS = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.CS, DICOM.Stringish);
DICOM.CS.prototype.vr = 'CS';


/**
 * DS: Decimal String, contains digits, ., +, - and e.
 */
DICOM.DS = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.DS, DICOM.Stringish);
DICOM.DS.prototype.vr = 'DS';


/**
 * IS: Integer String, contains digits, +, -
 */
DICOM.IS = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.IS, DICOM.Stringish);
DICOM.IS.prototype.vr = 'IS';


/**
 * DA: Date of the form YYYYMMDD, may also be YYYYMMDD-
 *  in range matches
 */
DICOM.DA = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.DA, DICOM.Stringish);
DICOM.DA.prototype.vr = 'DA';


/**
 * TM: Time HHMMSS.FFFFFF
 */
DICOM.TM = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.TM, DICOM.Stringish);
DICOM.TM.prototype.vr = 'TM';


/**
 * PN: Person name
 */
DICOM.PN = function (obj) {
    DICOM.VR.call(this, obj);
};
util.inherits(DICOM.PN, DICOM.Stringish);
DICOM.PN.prototype.vr = 'PN';


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
