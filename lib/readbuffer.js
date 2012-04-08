"use strict";

/*jslint nomen: true */

var assert = require('assert'),
    util = require('util'),
    fs = require('fs'),
    log4js = require('log4js'),
    EventEmitter = require('events').EventEmitter;

var verbose = false;
var log = log4js.getLogger("readbuffer");

var vtrace = function () {
    if (verbose && log.isDebugEnabled()) {
        log.debug.apply(log.debug, arguments);
    }
};

var ReadBuffer = function (stream, encoding) {
    EventEmitter.call(this);

    // current offset in the first buffer
    this.offset = 0;
    // read position in the stream
    this.streamPosition = 0;
    // additional queued buffers
    this.buffers = [];
    // sum of all buffers minus offset
    this.length = 0;
    // stream encoding for readline
    this.encoding = encoding || "UTF-8";

    // End of File
    this._stream_eof = false;

    if (stream) {
        this._stream = stream;
        this.registerStream(stream);
    }
};
util.inherits(ReadBuffer, EventEmitter);

ReadBuffer.prototype.registerStream = function (stream) {
    stream.on('data', this.onData.bind(this));
    stream.on('error', this.onError.bind(this));
    stream.on('end', this.onEnd.bind(this));
};

ReadBuffer.prototype.onData = function (buffer) {
    vtrace("ReadBuffer.onData");
    this.push(buffer);
    if (this._stream) {
        this._stream.pause();
    }
    this.handlePending();
};

ReadBuffer.prototype.handlePending = function () {
    var self = this, cont;
    if (self._pending !== undefined) {
        vtrace("handle pending action");
        cont = self._pending;
        self._pending = undefined;
        // process.nextTick(cont);
        cont();
    }
};

ReadBuffer.prototype.nextTickFunction = function (resumeMethod, arg1, arg2) {
    assert.ok(resumeMethod);
    var self = this,
        nextTickFn = function () {
            resumeMethod.call(self, arg1, arg2);
        };
    return nextTickFn;
};

ReadBuffer.prototype.nextTick = function (resumeMethod, arg1, arg2) {
    var fn = this.nextTickFunction(resumeMethod, arg1, arg2);
    process.nextTick(fn);
};

ReadBuffer.prototype.queuePending = function (resumeMethod, arg1, arg2) {
    var self = this;
    vtrace("queuing pending action");
    assert.ok(!self._pending);
    self._pending = self.nextTickFunction(resumeMethod, arg1, arg2);
    if (self._stream) {
        vtrace("calling stream resume");
        self._stream.resume();
    }
};


ReadBuffer.prototype.push = function (buffer) {
    var rc = this.buffers.push(buffer);
    this.length += buffer.length;
    return rc;
};

ReadBuffer.prototype.onEnd = function () {
    vtrace("ReadBuffer.onEnd");
    this._stream_eof = true;
    this.handlePending();
    this.emit('end');
};

ReadBuffer.prototype.onError = function (err) {
    vtrace("ReadBuffer.onError");
    this.error(err);
};

ReadBuffer.prototype.error = function (err) {
    vtrace("ReadBuffer.error - emitting error", err);
    this.emit('error', err);
};

ReadBuffer.prototype.has = function (bytes) {
    return bytes <= this.length;
};

// this only works for ascii range separators probably
// lf or cr should be safe
ReadBuffer.prototype.indexOf = function (needle) {
    assert.ok(needle.length === 1);
    if (this.length === 0) {
        return -1;
    }

    var i, j, buff, buffers, buffers_length, buff_length, what, offset, dpos;

    what = (new Buffer(needle))[0];
    buffers = this.buffers;
    buffers_length = buffers.length;
    buff = buffers[0];
    buff_length = buff.length;
    offset = this.offset;

    for (i = offset; i < buff_length; i += 1) {
        if (buff[i] === what) {
            return i - offset;
        }
    }

    dpos = buff_length - offset;
    for (j = 1; j < buffers_length; j += 1) {
        buff = buffers[j];
        buff_length = buff.length;

        for (i = 0; i < buff_length; i += 1) {
            if (buff[i] === what) {
                return dpos + i;
            }
        }
        dpos += buff_length;
    }

    return -1;
};

ReadBuffer.prototype.consume = function (bytes) {
    /*jslint white: true */
    assert.ok(this.has(bytes));
    var end = this.offset + bytes,
        buff = this.buffers[0],
        dstPos, dst, numBytes, len;
    // easy/fast case: first buffer is sufficient
    if (end <= buff.length) {
        dst = buff.slice(this.offset, end);
        this.offset += bytes;
    } else {
        // more complicated case: have to combine multiple buffers
        dst = new Buffer(bytes);
        buff.copy(dst, 0, this.offset, buff.length);
        dstPos = len = buff.length - this.offset;
        this.offset = 0;
        this.buffers.shift();
        numBytes = bytes - len;
        assert.ok(numBytes > 0);
        while (numBytes > 0) {
            buff = this.buffers[0];
            len = Math.min(numBytes, buff.length);
            buff.copy(dst, dstPos, 0, len);
            numBytes -= len;
            dstPos += len;
            if (len === buff.length) {
                this.buffers.shift();
                len = 0;
            }
        }
        this.offset = len;
    }

    this.length -= bytes;
    this.streamPosition += bytes;
    if (this.offset === buff.length) {
        this.offset = 0;
        this.buffers.shift();
    }
    return dst;
};


ReadBuffer.prototype.eof = function (cont) {
    var self = this,
        len = self.length;
    if (len > 0) {
        // we still have bytes to read, no eof
        cont(false);
    } else if (self._stream_eof) {
        // no bytes && stream end received, true eof
        cont(true);
    } else {
        // no bytes, but no stream end, postpone decision
        vtrace("next stream event decides about eof");
        self.queuePending(self.eof, cont);
    }
};


ReadBuffer.prototype.readline = function (cont) {
    var self = this,
        enc = self.encoding,
        idx = self.indexOf('\n'),
        line;
    if (idx >= 0) {
        line = self.consume(idx + 1).toString(enc);
        cont(line);
    } else if (self._stream_eof && self.length === 0) {
        self.error(new Error("EOF, can not read line"));
    } else if (self._stream_eof) {
        // return remaining incomplete line
        line = self.consume(self.length);
        cont(line);
    } else {
        // try again later ;)
        self.queuePending(self.readline, cont);
    }
};


ReadBuffer.prototype.read = function (bytes, cont) {
    var self = this,
        rcBuff;
    if (self.has(bytes)) {
        rcBuff = self.consume(bytes);
        cont(rcBuff);
    } else if (self._stream_eof) {
        self.error(new Error("EOF, can not read " + bytes));
    } else {
        // try again later ;)
        self.queuePending(self.read, bytes, cont);
    }
};

ReadBuffer.prototype.streamData = function (bytes, cont) {
    var self = this,
        numBytes = Math.min(bytes, self.length),
        buff;
    if (bytes === 0) {
        cont();
    } else if (numBytes === 0) {
        self.queuePending(self.streamData, bytes, cont);
    } else {
        buff = self.consume(numBytes);
        vtrace('ReadBuffer.streamData: ', buff);
        self.emit('data', buff);
        bytes -= numBytes;
        if (bytes === 0) {
            cont();
        } else {
            self.queuePending(self.streamData, bytes, cont);
        }
    }
};

exports.ReadBuffer = ReadBuffer;

if (require.main === module) {
    var eofCheck, readline, count = 0,
        rb = new ReadBuffer(fs.createReadStream(process.argv[2]));

    eofCheck = function (eof) {
        if (eof) {
            console.log("Line count:", count);
        } else {
            rb.readline(readline);
        }
    };

    readline = function (line) {
        console.log("readline", line);
        count += 1;
        // rb.asyncEof(eofCheck);
        rb.nextTick(rb.eof, eofCheck);
    };

    rb.eof(eofCheck);

}
