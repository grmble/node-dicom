var helper = require('../lib/helper');

exports.testArgumentSlice = function(test) {
    test.expect(3);

    (function (a,b) {
        var argslice = helper.argumentSlice(arguments, 2);
        test.deepEqual(argslice, [3, 4, 5]);
    })(1,2,3,4,5);

    (function (a,b) {
        var argslice = helper.argumentSlice(arguments, 2, 4);
        test.deepEqual(argslice, [3, 4]);
    })(1,2,3,4,5);

    (function (a,b) {
        var argslice = helper.argumentSlice(arguments, 2, 4);
        test.deepEqual(argslice, [3]);
    })(1,2,3);

    test.done();
};

exports.testMixin = function(test) {
    test.expect(2);

    (function () {
        function A () {
        }
        A.prototype.attribute = 17;
        A.prototype.fn = function() {
            return this.attribute
        };

        function B () {
        }

        helper.mixin(B, A);

        var b = new B();
        test.ok(b.fn() === undefined);
    })();

    (function () {
        function A () {
        }
        A.prototype.attribute = 17;
        A.prototype.fn = function() {
            return this.attribute;
        }

        function B () {
        }

        helper.mixin(B, A, 'attribute', 'fn');

        var b = new B();
        test.equal(b.fn(), 17);
    })();

    test.done();
};


exports.testChainCall = function(test) {
    test.expect(2);

    (function () {
        function A () {
        }
        A.prototype.methoda = function(a) {
            this.a = a;
        };
        A.prototype.methodb = function(b) {
            this.b = b;
        };

        var a = new A()
            , result = helper.chainCall(a
                , [a.methoda, 17]
                , [a.methodb, 4]);

        test.equal(result.a, 17);
        test.equal(result.b, 4);

        test.done();
    })();
};

