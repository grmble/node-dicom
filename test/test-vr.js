"use strict";

var VR = require('../lib/vr');

exports.testUL = function (test) {
    test.expect(4);

    var ul = new VR.LE.UL({rawValue: new Buffer([1, 2, 3, 4])});
    test.deepEqual(ul.decode(),  [0x04030201]);
    ul.rawValue = new Buffer([1, 2, 3, 4, 5, 6, 7, 8]);
    test.deepEqual(ul.decode(), [0x04030201,  0x08070605]);

    ul = new VR.BE.UL({rawValue: new Buffer([1, 2, 3, 4])});
    test.deepEqual(ul.decode(),  [0x01020304]);
    ul.rawValue = new Buffer([1, 2, 3, 4, 5, 6, 7, 8]);
    test.deepEqual(ul.decode(),  [0x01020304,  0x05060708]);


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
    test.deepEqual(ui.decode(),  ["1.2.3.4"]);

    ui.rawValue = new Buffer("1.3.12.2.1107.5.1.4.43511.30000005090506061531200001556\u0000");
    test.deepEqual(ui.decode(), ["1.3.12.2.1107.5.1.4.43511.30000005090506061531200001556"]);
    test.done();
};

exports.testOB = function (test) {
    test.expect(2);

    var input = new Buffer([1, 2, 3, 4, 5, 6, 7, 8]),
        ob = new VR.LE.OB({rawValue: input}),
        output;
    output = ob.decode();

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

    beResult = beOF.decode();
    leResult = leOF.decode();

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
    test.deepEqual(pn.decode(),  ["Spamless^Juergen",  "Grmble"]);

    test.done();
};

exports.testST = function (test) {
    test.expect(1);

    var stBuff = new Buffer("Spamless^Juergen\\Grmble"),
        st = new VR.LE.ST({rawValue: stBuff});
    test.deepEqual(st.decode(),  ["Spamless^Juergen\\Grmble"]);

    test.done();
};
