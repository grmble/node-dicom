"use strict";
/*jslint nomen: true */

var util = require('util');

var Delay = function (bindTo, fn, args) {
    this._bindTo = bindTo;
    this._fn = fn;
    this._args = args;
    this._value = undefined;
    this._mustCompute = true;
};

Delay.prototype.value = function () {
    if (this._mustCompute) {
        this._value = this._fn.apply(this._bindTo, this._args);
        this._mustCompute = false;
    }
    return this._value;
};

var delay = function (bindTo, fn) { // bindTo, fn, arguments
    if (typeof bindTo === 'function') {
        return new Delay(undefined, bindTo,
                Array.prototype.slice.call(arguments, 1));
    }
    return new Delay(bindTo, fn,
            Array.prototype.slice.call(arguments, 2));
};

var format = function () { // util format like argumens
    var i, args = Array.prototype.slice.call(arguments), len = args.length;
    for (i = 0; i < len; i += 1) {
        if (args[i] && typeof (args[i].value) === 'function') {
            args[i] = args[i].value();
        }
    }
    return util.format.apply(undefined, args);
};

var noop = function () {
};

var logFn = function (verbose, logFn) {
    if (logFn === undefined) {
        logFn = console.log;
    }
    if (verbose) {
        return function () {
            logFn(format.apply(undefined, arguments));
        };
    }
    return noop;
};

exports.delay = delay;
exports.logFn = logFn;

