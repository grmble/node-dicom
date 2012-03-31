"use strict";

var VR = require('../lib/vr');

exports.testUL = function (test) {
    test.expect(4);

    var ul = new VR.LE.UL();
    test.deepEqual(ul.decode(new Buffer([1, 2, 3, 4])),  [0x04030201]);
    test.deepEqual(ul.decode(new Buffer([1, 2, 3, 4, 5, 6, 7, 8])),  [0x04030201,  0x08070605]);

    ul = new VR.BE.UL();
    test.deepEqual(ul.decode(new Buffer([1, 2, 3, 4])),  [0x01020304]);
    test.deepEqual(ul.decode(new Buffer([1, 2, 3, 4, 5, 6, 7, 8])),  [0x01020304,  0x05060708]);

    test.done();
};


exports.testValueLengthBytes = function (test) {
    test.expect(4);
    var ul = new VR.LE.UL(),
        ob = new VR.LE.OB();
    test.equal(ul.explicitValueLengthBytes, 2);
    test.equal(ul.implicitValueLengthBytes, 4);

    test.equal(ob.explicitValueLengthBytes, 6);
    test.equal(ob.implicitValueLengthBytes, 4);

    test.done();
};

exports.testUI = function (test) {
    test.expect(1);

    var ui = new VR.LE.UI();

    test.deepEqual(ui.decode(new Buffer("1.2.3.4")),  ["1.2.3.4"]);
    test.done();
};

exports.testOB = function (test) {
    test.expect(2);

    var input = new Buffer([1, 2, 3, 4, 5, 6, 7, 8]),
        output = (new VR.LE.OB()).decode(input);

    test.equal(1,  output.length);
    test.equal(input.toString('binary'),  output.toString('binary'));
    test.done();
};

exports.testOF = function (test) {
    test.expect(4);

    var bePi = new Buffer(4),
		lePi = new Buffer(4),
		beResult,
		leResult;

    bePi.writeFloatBE(3.14,  0);
    lePi.writeFloatLE(3.14,  0);

    beResult = (new VR.BE.OF()).decode(bePi);
    leResult = (new VR.LE.OF()).decode(lePi);

    test.equal(1,  beResult.length);
    test.equal(1,  leResult.length);
    test.ok(Math.abs(leResult[0] - 3.14) < 0.0001);
    test.ok(Math.abs(beResult[0] - 3.14) < 0.0001);
    test.done();
};

exports.testPN = function (test) {
    test.expect(1);

    var pnBuff = new Buffer("Spamless^Juergen\\Grmble");
    test.deepEqual((new VR.LE.PN()).decode(pnBuff),  ["Spamless^Juergen",  "Grmble"]);

    test.done();
};

exports.testST = function (test) {
    test.expect(1);

    var stBuff = new Buffer("Spamless^Juergen\\Grmble");
    test.deepEqual((new VR.LE.ST()).decode(stBuff),  ["Spamless^Juergen\\Grmble"]);

    test.done();
};
