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
    test.expect(4);

    var pb = new parsebuffer.ParseBuffer(),
		result = [],
		theGroup = pb.enterGroup(20, function () {
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
