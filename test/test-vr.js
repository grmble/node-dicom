"use strict";

/*jslint nomen: true */

var VR = require('../lib/vr'),
    uids = require('../lib/uids');

exports.testUL = function (test) {
    test.expect(4);

    var ul = new VR.LE.UL({rawValue: new Buffer([1, 2, 3, 4])});
    test.deepEqual(ul.values(),  [0x04030201]);
    ul.setRawValue(new Buffer([1, 2, 3, 4, 5, 6, 7, 8]));
    test.deepEqual(ul.values(), [0x04030201,  0x08070605]);

    ul = new VR.BE.UL({rawValue: new Buffer([1, 2, 3, 4])});
    test.deepEqual(ul.values(),  [0x01020304]);
    ul.setRawValue(new Buffer([1, 2, 3, 4, 5, 6, 7, 8]));
    test.deepEqual(ul.values(),  [0x01020304,  0x05060708]);


    test.done();
};


exports.testValueLengthBytes = function (test) {
    test.expect(6);
    var ul = new VR.LE.UL(),
        ob = new VR.LE.OB(),
        lo = new VR.LE.LO();

    test.equal(ul.explicitValueLengthBytes, 2);
    test.equal(ul.implicitValueLengthBytes, 4);

    test.equal(ob.explicitValueLengthBytes, 6);
    test.equal(ob.implicitValueLengthBytes, 4);

    test.equal(lo.explicitValueLengthBytes, 2);
    test.equal(lo.implicitValueLengthBytes, 4);

    test.done();
};

exports.testUI = function (test) {
    test.expect(2);

    var ui = new VR.LE.UI({rawValue: new Buffer("1.2.3.4")});
    test.deepEqual(ui.values(),  ["1.2.3.4"]);

    ui.setRawValue(new Buffer("1.3.12.2.1107.5.1.4.43511.30000005090506061531200001556\u0000"));
    test.deepEqual(ui.values(), ["1.3.12.2.1107.5.1.4.43511.30000005090506061531200001556"]);
    test.done();
};

exports.testOB = function (test) {
    test.expect(2);

    var input = new Buffer([1, 2, 3, 4, 5, 6, 7, 8]),
        ob = new VR.LE.OB({rawValue: input}),
        output;
    output = ob.values();

    test.equal(1, output.length);
    test.equal(input.toString('binary'), output.toString('binary'));
    test.done();
};

exports.testOF = function (test) {
    test.expect(4);

    var bePi = new Buffer(4),
        lePi = new Buffer(4),
        beOF,
        leOF,
        beResult,
        leResult;

    bePi.writeFloatBE(3.14,  0);
    lePi.writeFloatLE(3.14,  0);

    leOF = new VR.LE.OF({rawValue: lePi});
    beOF = new VR.BE.OF({rawValue: bePi});

    beResult = beOF.values();
    leResult = leOF.values();

    test.equal(1,  beResult.length);
    test.equal(1,  leResult.length);
    test.ok(Math.abs(leResult[0] - 3.14) < 0.0001);
    test.ok(Math.abs(beResult[0] - 3.14) < 0.0001);
    test.done();
};

exports.testPN = function (test) {
    test.expect(1);

    var pnBuff = new Buffer("Spamless^Juergen\\Grmble"),
        pn = new VR.LE.PN({rawValue: pnBuff});
    test.deepEqual(pn.values(),  ["Spamless^Juergen",  "Grmble"]);

    test.done();
};

exports.testST = function (test) {
    test.expect(1);

    var stBuff = new Buffer("Spamless^Juergen\\Grmble"),
        st = new VR.LE.ST({rawValue: stBuff});
    test.deepEqual(st.values(),  ["Spamless^Juergen\\Grmble"]);

    test.done();
};

exports.testNoVR = function (test) {
    test.expect(3);

    var leItem = new VR.LE.NoVR({tag: "(FFFE,E000)"}),
        beItem = new VR.LE.NoVR({tag: "(FFFE,E000)"});

    test.equal(4, uids.ts.ExplicitVRLittleEndian.valueLengthBytes(leItem));
    test.equal(4, uids.ts.ImplicitVRLittleEndian.valueLengthBytes(leItem));
    test.equal(4, uids.ts.ExplicitVRBigEndian.valueLengthBytes(beItem));

    test.done();
};


exports.elementLength = function (test) {
    test.expect(12);

    var sq, pn, item;

    sq = new VR.LE.SQ({tag: '(0010,1002)'}); // other patient ids sequence
    sq.setElementLength(sq._unlimitedLength);
    test.ok(sq.nesting);
    test.ok(sq.unlimited);
    test.equal(sq.nestedLength, undefined);
    test.equal(sq.valueLength, undefined);

    pn = new VR.LE.PN({tag: '(0010,0010)'}); // patient name
    pn.setElementLength(15);
    test.ok(!pn.nesting);
    test.ok(!pn.unlimited);
    test.equal(pn.nestedLength, undefined);
    test.equal(pn.valueLength, 15);

    item = new VR.LE.NoVR({tag: '(FFFE,E000)'}); // Item
    item.setElementLength(15);
    test.ok(item.nesting);
    test.ok(!item.unlimited);
    test.equal(item.nestedLength, 15);
    test.equal(item.valueLength, undefined);

    test.done();

};

