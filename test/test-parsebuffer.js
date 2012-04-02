"use strict";

var parsebuffer = require('../lib/parsebuffer'),
    assert = require('assert'),
    log4js = require('log4js'),
    log = log4js.getLogger('test-parsebuffer');

function myDeepEqual(a, b) {
    try {
        assert.deepEqual(a, b);
        return true;
    } catch (ex) {
        log.error("not equal:", a, b);
        return false;
    }
}

var testCounter = 0;
function testBuffer(length) {
    var buff = new Buffer(length), i;
    for (i = 0; i < length; i += 1) {
        buff[i] = testCounter;
        testCounter += 1;
    }
    return buff;
}

exports.testRequest = function (test) {
    test.expect(1);

    var pb = new parsebuffer.ParseBuffer(),
        result = [];
    pb.request(8, parsebuffer.setter(result));
    pb.request(8, parsebuffer.setter(result));
    pb.request(4, parsebuffer.setter(result, function () {
        test.ok(myDeepEqual(result,
                [new Buffer([0, 1, 2, 3, 4, 5, 6, 7]),
                new Buffer([8, 9, 10, 11, 12, 13, 14, 15]),
                new Buffer([16, 17, 18, 19])]));
    }));

    pb.onData(testBuffer(6));
    pb.onData(testBuffer(6));
    pb.onData(testBuffer(4));
    pb.onData(testBuffer(4));

    test.done();
};

exports.testGroup = function (test) {
    test.expect(5);

    var pb = new parsebuffer.ParseBuffer(),
        result = [],
        theGroup = pb.enterGroup(20, function () {
            log.debug("group enter callback");
            test.ok(result.length === 0);
        }, function () {
            log.debug("group callback");
            test.ok(myDeepEqual(result,
                    [new Buffer([20, 21, 22, 23, 24, 25, 26, 27]),
                    new Buffer([28, 29, 30, 31, 32, 33, 34, 35]),
                    new Buffer([36, 37, 38, 39])]));
            test.ok(!theGroup.active);
        });

    pb.request(8, parsebuffer.setter(result));
    pb.request(8, function (buff) {
        result.push(buff);
        test.ok(theGroup.active);
    });
    pb.request(4, function (buff) {
        log.debug("last request");
        result.push(buff);
        // in the callback of the last group member, this is false
        // before reading the dataelement value, it would be true
        test.ok(!theGroup.active);
    });

    pb.onData(testBuffer(20));

    test.done();
};

exports.testExplicitGroup = function (test) {
    test.expect(5);

    var pb = new parsebuffer.ParseBuffer(),
        result = [],
        theGroup = pb.enterGroup(function (group2) {
            log.debug("explicit group callback", result);
            test.ok(myDeepEqual(result,
                    [new Buffer([40, 41, 42, 43, 44, 45, 46, 47]),
                    new Buffer([48, 49, 50, 51, 52, 53, 54, 55])]));
            test.ok(!theGroup.active);

            // test that we get the group argument in the end callback
            test.equal(group2, theGroup);
        });

    pb.request(8, parsebuffer.setter(result));
    pb.request(8, function (buff) {
        result.push(buff);
        test.ok(theGroup.active);
        pb.exitGroup();
    });
    pb.request(4, function (buff) {
        log.debug("last request");
        result.push(buff);
        // in the callback of the last group member, this is false
        // before reading the dataelement value, it would be true
        test.ok(!theGroup.active);
    });

    pb.onData(testBuffer(20));

    test.done();
};

exports.testEOF = function (test) {
    test.expect(2);

    var pb = new parsebuffer.ParseBuffer();
    test.ok(!pb.eof);
    pb.onEnd();
    test.ok(pb.eof);

    test.done();
};

exports.testError = function (test) {
    test.expect(2);

    var pb = new parsebuffer.ParseBuffer();
    test.ok(!pb.error);
    pb.request(2, function (buff) {
        // this should never be called
        test.ok(false);
    });
    pb.onError(new Error("testing error handling"));
    test.ok(pb.error);

    // this should not do anything because the parsebuffer is in error
    pb.onData(new Buffer([1, 2]));


    test.done();
};

exports.testRequestStream = function (test) {
    test.expect(1);

    var pb = new parsebuffer.ParseBuffer(),
        count = 0;
    pb.requestStream(20, function (buffer) { count += 1; },
            function () {
                test.equal(count, 4);
                test.done();
            });

    pb.onData(testBuffer(6));
    pb.onData(testBuffer(6));
    pb.onData(testBuffer(4));
    pb.onData(testBuffer(4));

};

