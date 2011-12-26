/**
 * slice for arguments
 */
exports.argumentSlice = function (args, start, end) {
    var acc = []
    if (end === undefined) {
        end = args.length
    } else {
        end = Math.min(args.length, end)
    }

    for(var i = start; i < end; i++) {
        acc.push(args[i])
    }

    return acc
}

/**
 *
 * mixin from dst to src
 *
 * if additional arguments are given, they specify the names to mixin.
 *
 * otherwise all functions are taken
 *
 */
exports.mixin = function (dst, src /*names */) {
    var argslice = exports.argumentSlice(arguments, 2)
        , to = dst.prototype
        , from = src.prototype

    if (argslice.length == 0) {
        for(var m in from) {
            if (typeof from[m] != 'function') continue;
            to[m] = from[m]
        }
    } else {
        argslice.forEach(function (m) {
            to[m] = from[m]
        })
    }
}


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
exports.chainCall = function (bindTo) {
    var calls = exports.argumentSlice(arguments, 1)
        , callsLen = calls.length
        , i, method, args, result = bindTo
    for(i = 0; i < callsLen; i++) {
        method = calls[i][0], args = calls[i].slice(1)
        result = method.apply(bindTo, args)
            , bindTo = (result === undefined) ? bindTo : result
    }
    return bindTo
}

