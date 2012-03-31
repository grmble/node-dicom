"use strict";

var uids = require('../lib/uids');

exports.testTransferSyntax = function (test) {
    test.expect(6);

    var evrle = uids.ts.ExplicitVRLittleEndian,
        ivrle = uids.ts.ImplicitVRLittleEndian,
        evrbe = uids.ts.ExplicitVRBigEndian;

    test.ok(evrle.explicit);
    test.ok(evrle.littleEndian);
    test.ok(!ivrle.explicit);
    test.ok(ivrle.littleEndian);
    test.ok(evrbe.explicit);
    test.ok(!evrbe.littleEndian);

    test.done();
};

exports.testAccessByUid = function (test) {
    test.expect(1);

    test.equal(uids.uid('1.2.840.10008.1.2.1'), uids.ts.ExplicitVRLittleEndian);

    test.done();
};
