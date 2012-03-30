"use strict";

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
        for (m in from) {
			if (from.hasOwnProperty(m)) {
				if (typeof from[m] !== 'function') {
					continue;
				}
				to[m] = from[m];
			}
        }
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
	var newDict = { }, key, v;
	if (keyname === undefined) {
		for (key in dict) {
			if (dict.hasOwnProperty(key)) {
				newDict[dict[key]] = key;
			}
		}
	} else {
		for (key in dict) {
			if (dict.hasOwnProperty(key)) {
				v = dict[key][keyname];
				newDict[v] = key;
			}
		}
	}
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

