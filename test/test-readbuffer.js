"use strict";

/*jslint nomen: true */

var fs = require('fs'),
    path = require('path'),
    util = require('util'),
    ReadBuffer = require('../lib/readbuffer.js').ReadBuffer;

exports.testPushConsume = function (test) {
    test.expect(10);
    var rb = new ReadBuffer();
    rb.push(new Buffer("0123"));
    rb.push(new Buffer("4567"));
    rb.push(new Buffer("89AB"));
    rb.push(new Buffer("CDEF"));
    rb.push(new Buffer("0123"));
    rb.push(new Buffer("4567"));
    rb.push(new Buffer("89AB"));
    rb.push(new Buffer("CDEF"));
    // one buffer beginning / middle
    test.equal(rb.consume(2).toString(), "01");
    // one buffer middle / end
    test.equal(rb.consume(2).toString(), "23");
    // one buffer beginning / end
    test.equal(rb.consume(4).toString(), "4567");
    // mult buffer, beginning / middle
    test.equal(rb.consume(6).toString(), "89ABCD");
    // mult buffer, middle / end
    test.equal(rb.consume(6).toString(), "EF0123");
    // mult buffer, beginning / end
    test.equal(rb.consume(8).toString(), "456789AB");

    test.equal(rb.length, 4);
    test.ok(rb.has(4));
    test.ok(rb.has(0));
    test.ok(!rb.has(5));

    test.done();
};

exports.testIndexOf = function (test) {
    test.expect(10);
    var rb = new ReadBuffer();
    rb.push(new Buffer("asdf"));
    rb.push(new Buffer("jkl"));
    test.equal(-1, rb.indexOf('\n'));
    test.equal(0, rb.indexOf('a'));
    test.equal(1, rb.indexOf('s'));
    test.equal(3, rb.indexOf('f'));
    test.equal(4, rb.indexOf('j'));
    rb.consume(2);
    test.equal(-1, rb.indexOf('a'));
    test.equal(-1, rb.indexOf('s'));
    test.equal(0, rb.indexOf('d'));
    test.equal(1, rb.indexOf('f'));
    test.equal(2, rb.indexOf('j'));
    test.done();
};

exports.testReadline = function (test) {
    test.expect(1);

    var eofCheck, readline, result = [],
        rb = new ReadBuffer(fs.createReadStream(path.join(__dirname, "test.txt")));

    eofCheck = function (eof) {
        if (eof) {
            test.deepEqual(result,
                ["Line1\n", "Line2\n", "Line3\n", "Line4\n", "Line5\n"]);
            test.done();
        } else {
            rb.readline(readline);
        }
    };

    readline = function (line) {
        // console.log("readline", line);
        result.push(line);
        rb.eof(eofCheck);
    };

    rb.eof(eofCheck);
};

exports.testFixedRead = function (test) {
    test.expect(1);

    var eofCheck, read, result = [],
        rb = new ReadBuffer(fs.createReadStream(path.join(__dirname, "test.txt")));

    eofCheck = function (eof) {
        // console.log("eof check", eof);
        if (eof) {
            test.deepEqual(result,
                ["Line1\n", "Line2\n", "Line3\n", "Line4\n", "Line5\n"]);
            test.done();
        } else {
            rb.read(6, read);
        }
    };

    read = function (buffer) {
        // console.log("read", buffer);
        result.push(buffer.toString());
        rb.eof(eofCheck);
    };

    rb.eof(eofCheck);
};

exports.testReadlineEOF = function (test) {
    test.expect(2);

    var rb = new ReadBuffer(fs.createReadStream(path.join(__dirname, "test.txt")));

    rb.on('error', function (err) {
        test.ok(err); // we have an error object
        test.ok(util.isError(err));
        test.done();
    });

    rb.read(30, function () {
        rb.readline(function () {
            test.ok(false); // we should not reach this
        });
    });
};

exports.testFixedReadEOF = function (test) {
    test.expect(2);

    var rb = new ReadBuffer(fs.createReadStream(path.join(__dirname, "test.txt")));

    rb.on('error', function (err) {
        test.ok(err); // we have an error object
        test.ok(util.isError(err));
        test.done();
    });

    rb.read(20, function () {
        rb.read(20, function () {
            test.ok(false); // we should not reach this
        });
    });
};

exports.testStreamData = function (test) {
    test.expect(2);

    var result = [],
        rb = new ReadBuffer();

    rb.on('data', function (buff) { result.push(buff.toString()); });
    rb.on('end', function (buff) {
        test.equal(result, "STREAMCALLBACKDONE");
        test.done();
    });

    rb.onData(new Buffer("asdf"));
    rb.onData(new Buffer("jkl;"));
    rb.nextTick(rb.onData, new Buffer("xxxx"));
    rb.nextTick(rb.onData, new Buffer("yyyy"));
    rb.nextTick(rb.onEnd);


    rb.streamData(16, function () {
        test.deepEqual(result, ["asdfjkl;", "xxxx", "yyyy"]);
        result = "STREAMCALLBACKDONE";
    });
};
