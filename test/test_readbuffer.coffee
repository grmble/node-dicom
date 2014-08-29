#! /usr/bin/env coffee
readbuffer = require("../lib/readbuffer")

exports.ReadBufferTest =
  "test push/consume": (test) ->
    test.expect 10
    rb = readbuffer()
    rb.push(new Buffer("0123"))
    rb.push(new Buffer("4567"))
    rb.push(new Buffer("89AB"))
    rb.push(new Buffer("CDEF"))
    rb.push(new Buffer("0123"))
    rb.push(new Buffer("4567"))
    rb.push(new Buffer("89AB"))
    rb.push(new Buffer("CDEF"))
    # one buffer beginning / middle
    test.equal(rb.consume(2).toString(), "01")
    # one buffer middle / end
    test.equal(rb.consume(2).toString(), "23")
    # one buffer beginning / end
    test.equal(rb.consume(4).toString(), "4567")
    # mult buffer, beginning / middle
    test.equal(rb.consume(6).toString(), "89ABCD")
    # mult buffer, middle / end
    test.equal(rb.consume(6).toString(), "EF0123")
    # mult buffer, beginning / end
    test.equal(rb.consume(8).toString(), "456789AB")

    test.equal(rb.length, 4)
    test.ok(rb.has(4))
    test.ok(rb.has(0))
    test.ok(!rb.has(5))

    test.done()

  "test indexOf": (test) ->
    test.expect(10)
    rb = readbuffer()
    rb.push(new Buffer("asdf"))
    rb.push(new Buffer("jkl"))
    test.equal(-1, rb.indexOf('\n'))
    test.equal(0, rb.indexOf('a'))
    test.equal(1, rb.indexOf('s'))
    test.equal(3, rb.indexOf('f'))
    test.equal(4, rb.indexOf('j'))
    rb.consume(2)
    test.equal(-1, rb.indexOf('a'))
    test.equal(-1, rb.indexOf('s'))
    test.equal(0, rb.indexOf('d'))
    test.equal(1, rb.indexOf('f'))
    test.equal(2, rb.indexOf('j'))
    test.done()
    
