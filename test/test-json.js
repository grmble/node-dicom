"use strict";

var tags = require('../lib/tags'),
    json = require('../lib/json');

exports.testObjectData = function (test) {
    test.expect(1);
    var resultData = [],
        obj = {},
        oe = new json.ObjectEmitter(obj);
    obj[tags.QueryRetrieveLevel] = "STUDY";
    obj[tags.StudyInstanceUID] = "1.2.3.4";

    oe.on('data', function (buffer) {
        console.log("Got data", buffer);
        resultData.push(buffer);
    });
    oe.on('end', function () {
        test.deepEqual(resultData,
                [new Buffer("STUDY"), new Buffer("1.2.3.4")]);
        test.done();
    });

    oe.emitEvents();
};
