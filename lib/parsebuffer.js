"use strict";

/**
 * ParseBuffer abstraction.
 *
 * o Can read byte-wise from a stream
 * o implicit and explicit grouping
 */

var util = require('util'),
    assert = require('assert'),
    events = require('events'),
    helper = require('./helper'),
    log4js = require('log4js'),
    log = log4js.getLogger('parsebuffer'),
    verbose = false;

/**
 * ParseBuffer constructor.
 *
 * Takes an optional stream; if given it autoregisters onData/onEnd
 */
function ParseBuffer(stream) {
    // current buffer
    this.currentBuffer = null;
    // read position in current buffer
    this.currentPosition = 0;
    // read position in the stream
    this.streamPosition = 0;
    // additional queued buffers
    this.bufferQueue = [];
    // sum of all queued buffers and current buffer minus current position
    this.bufferedBytes = 0;
    // records of bytes/callback
    this.requestQueue = [];

    // stack of groups
    this.groupStack = [];
    this.groupEnd = null;

    // End of File
    this.eof = undefined;
    // An error
    this.error = undefined;

    if (stream) {
        this.registerStream(stream);
    }
}
util.inherits(ParseBuffer, events.EventEmitter);

/**
 * if an error or eof occurred, we dont continue work
 */
ParseBuffer.prototype.isStopped = function () {
    return this.eof || this.error;
};


var stopAwareFn = function (msg, realFunction) {
    return function () {
        var self = this;
        if (self.isStopped()) {
            log.warn("ParseBuffer is shut down:", msg);
        } else {
            return realFunction.apply(self, arguments);
        }
    };
};

/**
 * Register the parsebuffer for the data/end events.
 */
ParseBuffer.prototype.registerStream = function (stream) {
    stream.on('error', this.onError.bind(this));
    stream.on('data', this.onData.bind(this));
    stream.on('end', this.onEnd.bind(this));
};

/**
 * Callback for stream data events.
 *
 * Use registerStream to register for the events.
 */
ParseBuffer.prototype.onData = stopAwareFn("onData", function (buffer) {
    log.trace(util.format("ParseBuffer.onData", buffer));

    if (this.currentBuffer) {
        this.bufferQueue.push(buffer);
    } else {
        this.currentBuffer = buffer;
        this.currentPosition = 0;
    }

    this.bufferedBytes += buffer.length;

    this.consumeRequests();
});

/**
 * Callback for stream data events.
 *
 * Use registerStream to register for the events.
 */
ParseBuffer.prototype.onEnd = function () {
    log.trace("ParseBuffer.onEnd");
    this.eof = true;

    this.requestQueue.forEach(function (request) {
        if (request.endCallback) {
            request.endCallback();
        } else {
            request.callback();
        }
    });
    this.requestQueue = [];
};

/**
 * Callback for stream or other error events
 */
ParseBuffer.prototype.onError = function (error) {
    log.error("ParseBuffer.onError", arguments);
    this.error = error;
};

/**
 * request a buffer with bytes length to be sent to callback.
 */
ParseBuffer.prototype.request = stopAwareFn("request", function (bytes, callback) {
    this.requestQueue.push({bytes: bytes, callback: callback});
    this.consumeRequests();
});

/**
 * stream buffers of total length to callback.
 */
ParseBuffer.prototype.requestStream = stopAwareFn("requestStream", function (bytes, callback, endCallback) {
    this.requestQueue.push({bytes: bytes, callback: callback, endCallback: endCallback, stream: true});
    this.consumeRequests();
});


/*
 * consume as many of the queued requests as possible.
 */
ParseBuffer.prototype.consumeRequests = function () {
    var request;
    while (!this.isStopped()) {
        request = this.requestQueue[0];
        if (this.isRequestReady(request)) {
            this.requestQueue.shift();
            if (request.stream) {
                this.consumeStreamRequest(request);
            } else {
                this.consumeImmediateRequest(request);
            }
        } else {
            break;
        }
    }
};

/*
 * are we ready to handle the request?
 */
ParseBuffer.prototype.isRequestReady = function (request) {
    var ready;
    if (request) {
        if (request.stream) {
            ready = 0 < this.bufferedBytes;
        } else {
            ready = request.bytes <= this.bufferedBytes;
        }
    }
    return ready;
};

/*
 * consume a single non-streaming request
 */
ParseBuffer.prototype.consumeImmediateRequest = stopAwareFn("consumeImmediateRequest", function (request) {
    var buffer = new Buffer(request.bytes),
        slices = this.extractBufferSlices(request),
        pos = 0;
    // if there is only one slice, we can just use that ...
    if (slices.length === 1) {
        buffer = slices[0];
    } else {
        slices.forEach(function (bs) {
            bs.copy(buffer, pos);
            pos += bs.length;
        });
    }
    assert.equal(request.bytes, 0);
    this.finalizeRequest(request, buffer);
});


/*
 * consume a streaming request
 */
ParseBuffer.prototype.consumeStreamRequest = stopAwareFn("consumeStreamRequest", function (request) {
    var slices = this.extractBufferSlices(request),
        lastIdx = slices.length - 1;
    slices.forEach(function (bs, idx) {
        if (verbose) {
            log.trace(util.format("ParseBuffer.consumeStreamRequest: ", bs));
        }
        request.callback(bs);
    });
    if (request.bytes > 0) {
        if (verbose) {
            log.trace(util.format("request not finished yet, unshifting", request));
        }
        this.requestQueue.unshift(request);
    } else {
        request.endCallback();
    }
});


/*
 * extract buffers/buffer slices for request
 */
ParseBuffer.prototype.extractBufferSlices = function (request) {
    var bytes, srcPos, currentBytes, srcEnd, numCopied, topGroup, slices = [];

    // use the current part
    bytes = request.bytes;
    srcPos = this.currentPosition;
    currentBytes = this.currentBuffer.length - srcPos;
    srcEnd = (currentBytes < bytes) ? this.currentBuffer.length : srcPos + bytes;
    numCopied = srcEnd - srcPos;

    slices.push(this.currentBuffer.slice(srcPos, srcEnd));

    bytes -= numCopied;
    request.bytes = bytes;
    this.bufferedBytes -= numCopied;
    this.currentPosition = srcEnd;
    this.streamPosition += numCopied;
    if (srcEnd === this.currentBuffer.length) {
        this.currentPosition = 0;
        this.currentBuffer = this.bufferQueue.shift();
    }

    while (bytes > 0 && this.currentBuffer) {
        currentBytes = this.currentBuffer.length;
        numCopied = (currentBytes < bytes) ? this.currentBuffer.length : bytes;

        slices.push(this.currentBuffer.slice(0, numCopied));

        bytes -= numCopied;
        request.bytes = bytes;
        this.bufferedBytes -= numCopied;
        this.currentPosition = numCopied;
        this.streamPosition += numCopied;
        if (numCopied === this.currentBuffer.length) {
            this.currentPosition = 0;
            this.currentBuffer = this.bufferQueue.shift();
        }
    }

    return slices;
};


// handle grouping and call request callback
ParseBuffer.prototype.finalizeRequest  = function (request, buffer) {
    var topGroup;
    // 2 stage implicit group endGroup
    // we have to false the active property *before* calling the last callback
    // (the one for the rawvalue), because that triggers the decodeDicomElement
    // callback, and that triggers the loop check
    topGroup = this.group();
    if (topGroup && this.streamPosition >= this.groupEnd) {
        topGroup.active = false;
    }

    if (buffer) {
        if (verbose) {
            log.trace(util.format("ParseBuffer.finalizeRequest: consuming", buffer));
        }
        request.callback(buffer);
    }

    // now get rid of the group, *after* the request callback
    // this ensures that the group callback is not called before the last element
    // callback - necessary for explicit groups
    if (topGroup && !topGroup.active) {
        this.exitGroup(true);
    }
};

/**
 * Get the current group or undefined
 */
ParseBuffer.prototype.group = function () {
    return this.groupStack[this.groupStack.length - 1];
};

/**
 * Enter into a new group.
 *
 * A group may have a predermined length which will make the group auto-exit
 * after all its bytes have been requested.  This is an implicit group.
 * An explicit group does not end without application calling popGroup.
 *
 * If only one callback is given, it is the endcallback.
 */
ParseBuffer.prototype.enterGroup = function (length, startCallback, endCallback) {
    var end, theGroup;
    if (typeof length === 'function') {
        endCallback = startCallback;
        startCallback = length;
        length = undefined;
    }
    if (!endCallback && startCallback) {
        endCallback = startCallback;
        startCallback = undefined;
    }
    end = (length) ? this.streamPosition + length : undefined;
    this.groupStack.push({length: length, end: end, callback: endCallback, active: true});
    this.groupEnd = end;
    theGroup = this.group();
    if (verbose) {
        log.trace("ParseBuffer.enterGroup", theGroup);
    }
    if (startCallback) {
        startCallback(theGroup);
    }
    return theGroup;
};

/**
 * Exit an (explicit) group, if any.
 *
 * At this point the group callback will be called.  For implicit groups,
 * this will be called internally with the 'force' arg true.  Don't call this
 * with the force flag set.
 */
ParseBuffer.prototype.exitGroup = stopAwareFn("exitGroup", function (internalDontUse) {
    var mustEnd, group = this.group();
    if (group) {
        // internal=implicit: end non-active groups
        // explicit: end top-group, assert a group length
        if (internalDontUse) {
            mustEnd = !group.active;
        } else {
            assert.equal(group.length, undefined);
            mustEnd = true;
        }

        if (mustEnd) {
            this.groupStack.pop();
            this.groupEnd = (this.group()) ? this.group().end : undefined;
            if (verbose && log.isTraceEnabled()) {
                log.trace("ParseBuffer.exitGroup", internalDontUse, group);
            }
            group.active = false;
            if (group.callback) {
                group.callback(group);
            }
        }
    }
});

exports.ParseBuffer = ParseBuffer;


/**
 * helper to use with ParseBuffer.request
 *
 * it returns a callback function that sets an index in an array and optionally calls
 * an additional callback
 *
 * pb.request(2, setter(arr,0));
 * pb.request(2, setter(arr,1));
 * pb.request(4, setter(arr,2, function () {
 *   // now we can use all those array members ...
 * }));
 */
exports.setter = function (obj, idx, callback) {
    if (callback === undefined && typeof idx === 'function') {
        callback = idx;
        idx = undefined;
    }
    return function (buffer) {
        if (idx === undefined) {
            obj.push(buffer);
        } else {
            obj[idx] = buffer;
        }
        if (callback) {
            callback(obj);
        }
    };
};
