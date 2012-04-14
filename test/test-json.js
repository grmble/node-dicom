"use strict";

var tags = require('../lib/tags'),
    json = require('../lib/json');

exports.testObjectData = function (test) {
    test.expect(1);
    var resultData = [],
        obj = {
            QueryRetrieveLevel: "STUDY",
            StudyInstanceUID: "1.2.3.4",
        },
        oe = new json.ObjectEmitter(obj);

    oe.on('data', function (buffer) {
        console.log("Got data", buffer);
        resultData.push(buffer.toString());
    });
    oe.on('end', function () {
        test.deepEqual(resultData, ["STUDY ", "1.2.3.4\u0000"]);
        test.done();
    });

    oe.emitEvents();
};
