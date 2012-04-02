"use strict";

var log4js = require('log4js');

/**
 * slice for arguments
 */
exports.argumentSlice = function (args, start, end) {
    var acc = [], i;

    if (end === undefined) {
        end = args.length;
    } else {
        end = Math.min(args.length, end);
    }

    for (i = start; i < end; i += 1) {
        acc.push(args[i]);
    }

    return acc;
};

/**
 * forKeys - for in / hasOwnProperty helper
 */
exports.forKeys = function (obj, callback) {
    var k;
    for (k in obj) {
        if (obj.hasOwnProperty(k)) {
            callback(k, obj[k]);
        }
    }
};
var forKeys = exports.forKeys;

/**
 *
 * mixin from dst to src
 *
 * if additional arguments are given, they specify the names to mixin.
 *
 * otherwise all functions are taken
 *
 */
exports.mixin = function (dst, src) {
    var argslice = exports.argumentSlice(arguments, 2),
        to = dst.prototype,
        from = src.prototype,
        m;

    if (argslice.length === 0) {
        forKeys(from, function (k, v) {
            if (typeof v === 'function') {
                to[k] = v;
            }
        });
    } else {
        argslice.forEach(function (m) {
            to[m] = from[m];
        });
    }
};

/**
 * invert a dictionary
 *
 * Switches key and value in a dictionary.
 *
 * If a keyname is given, it gives the the attribute name in the value
 * for the new key. 
 */
exports.invertDictionary = function (dict, keyname) {
    var newDict = { }, k, v;
    forKeys(dict, function (k, v) {
        if (newDict.hasOwnProperty(v)) {
            throw new Error("Not invertable: multiple " + v);
        }
        if (keyname === undefined) {
            newDict[v] = k;
        } else {
            newDict[v[keyname]] = k;
        }
    });
    return newDict;
};

/**
 *
 * chain method calls
 *
 * example:
 * chainCall(initialThis, [this.method1, arg1, arg1]
 *      [this.method2, arg3, arg4]);
 *
 *  the chain will be started by calling method1 bound to intialThis.
 *  method2 will be called bound to the result of method1, and so on.
 *  the final result is returned.
 *
 *  For convenience, if any method returns undefined, the last bound this
 *  is reused.
 *
 */
exports.chainCall = function (initialBind) {
    var calls = exports.argumentSlice(arguments, 1),
        callsLen = calls.length,
        bindTo = initialBind,
        result = bindTo,
        i,
        method,
        args;
    for (i = 0; i < callsLen; i += 1) {
        method = calls[i][0];
        args = calls[i].slice(1);
        result = method.apply(bindTo, args);
        bindTo = (result === undefined) ? bindTo : result;
    }
    return bindTo;
};


/**
 *
 * Chain method calls with callbacks
 *
 * this.someMethod(1, function(a, b) {
 *   this.someMethod2(2, 3, a, b, function (result) {
 *     this.someMethod3(result, finalCallbackFunction);
 *     });
 *  });
 *
 *  is the same as:
 *  chainCallbacks(this, finalCallbackFunction,
 *   [someFunc, 1],
 *   [someFunc2, 2, 3],
 *   [someFunc3]);
 */
exports.chainCallbacks = function (initialBind, finalCallback) {
    var calls = exports.argumentSlice(arguments, 2),
        callsLen = calls.length,
        bindTo = initialBind,
        result = bindTo;
    calls.forEach(function (callDesc) {
        var method = callDesc[0],
            curryArgs = callDesc.slice(1),
            result;
    });
    throw new Error("implement me!");
};


/**
 *
 * noop function
 *
 */
exports.noop = function () {
};
