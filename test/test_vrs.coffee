#! /usr/bin/env coffee

vrs = require "../lib/vrs"

b_1704 = new Buffer([0x17, 0x04])
b_deadbeef = new Buffer([0xDE, 0xAD, 0xBE, 0xEF])

exports.LittleEndianTest =
  "test unpacking": (test) ->
    test.expect 2
    test.equal 0x0417, vrs.LITTLE_ENDIAN.unpack_uint16(b_1704)
    test.deepEqual [0xADDE, 0xEFBE], vrs.LITTLE_ENDIAN.unpack_uint16s(b_deadbeef, 2)
    test.done()
  "test packing": (test) ->
    test.expect 1
    test.deepEqual b_deadbeef, vrs.LITTLE_ENDIAN.pack_uint16s([0xADDE, 0xEFBE])
    test.done()

exports.BigEndianTest =
  "test unpacking": (test) ->
    test.expect 2
    test.equal 0x1704, vrs.BIG_ENDIAN.unpack_uint16(b_1704)
    test.deepEqual [0xDEAD, 0xBEEF], vrs.BIG_ENDIAN.unpack_uint16s(b_deadbeef, 2)
    test.done()
  "test packing": (test) ->
    test.expect 1
    test.deepEqual b_deadbeef, vrs.BIG_ENDIAN.pack_uint16s([0xDEAD, 0xBEEF])
    test.done()

DEF_CTX = new vrs.Context({}, {})

exports.ATTest =
  "test encoding": (test) ->
    test.expect 2
    at = new vrs.AT(DEF_CTX, null, [0x00100012, 0x0020001D])
    expect = new Buffer([0x10, 0x00, 0x12, 0x00, 0x20, 0x00, 0x1D, 0x00])
    test.deepEqual expect, at.buffer
    at = new vrs.AT(DEF_CTX, null, [0xfffee000])
    expect = new Buffer([0xfe, 0xff, 0x00, 0xe0])
    test.deepEqual expect, at.buffer
    test.done()
  "test decoding": (test) ->
    test.expect 1
    input = new Buffer([0x10, 0x00, 0x12, 0x00, 0x20, 0x00, 0x1D, 0x00])
    at = new vrs.AT(DEF_CTX, input)
    test.deepEqual [0x00100012, 0x0020001D], at.values()
    test.done()
    

exports.FDTest =
  "test doubles": (test) ->
    test.expect 1
    _vals = [0.5, 1000.0]
    fd = new vrs.FD(DEF_CTX, null, _vals)
    # this relies on the fact that the values are not stored
    # converting to buffer and converting back should be the same
    test.deepEqual _vals, fd.values()
    test.done()


exports.FLTest =
  "test floats": (test) ->
    test.expect 1
    _vals = [0.5, 1000.0]
    fl = new vrs.FL(DEF_CTX, null, _vals)
    # this relies on the fact that the values are not stored
    # converting to buffer and converting back should be the same
    test.deepEqual _vals, fl.values()
    test.done()

exports.SLTest =
  "test encode": (test) ->
    test.expect 1
    sl = new vrs.SL(DEF_CTX, null, [0x01020304, 0x05060708])
    test.deepEqual sl.buffer, new Buffer([4..1].concat([8..5]))
    test.done()
  "test decode": (test) ->
    test.expect 1
    sl = new vrs.SL(DEF_CTX, new Buffer([4..1].concat([8..5])))
    test.deepEqual [0x01020304, 0x05060708], sl.values()
    test.done()

exports.SSTest =
  "test encode": (test) ->
    test.expect 1
    ss = new vrs.SS(DEF_CTX, null, [0x0102, 0x0506])
    test.deepEqual ss.buffer, new Buffer([2..1].concat([6..5]))
    test.done()
  "test decode": (test) ->
    test.expect 1
    ss = new vrs.SS(DEF_CTX, new Buffer([2..1].concat([6..5])))
    test.deepEqual [0x0102, 0x0506], ss.values()
    test.done()

exports.ULTest =
  "test encode": (test) ->
    test.expect 1
    ul = new vrs.UL(DEF_CTX, null, [0x01020304, 0x05060708])
    test.deepEqual ul.buffer, new Buffer([4..1].concat([8..5]))
    test.done()
  "test decode": (test) ->
    test.expect 1
    ul = new vrs.UL(DEF_CTX, new Buffer([4..1].concat([8..5])))
    test.deepEqual [0x01020304, 0x05060708], ul.values()
    test.done()

exports.USTest =
  "test encode": (test) ->
    test.expect 1
    us = new vrs.US(DEF_CTX, null, [0x0102, 0x0506])
    test.deepEqual us.buffer, new Buffer([2..1].concat([6..5]))
    test.done()
  "test decode": (test) ->
    test.expect 1
    us = new vrs.US(DEF_CTX, new Buffer([2..1].concat([6..5])))
    test.deepEqual [0x0102, 0x0506], us.values()
    test.done()


#
# for string tests:
#
# * multi-values
# * no multi-values, e.g. LT with backslashes in there
# * space-padding
# * zero-padding (UI)

exports.StringMultiValuesTest =
  "test multivalue": (test) ->
    test.expect 2
    lo = new vrs.LO(DEF_CTX, null, ["Juergen", "Gmeiner"])
    test.deepEqual new Buffer("Juergen\\Gmeiner ", "binary"), lo.buffer
    test.deepEqual ["Juergen", "Gmeiner"], lo.values()
    test.done()
  "test no multivalue": (test) ->
    test.expect 2
    st = new vrs.ST(DEF_CTX, null, ["Some text with \\ in there"])
    test.deepEqual new Buffer("Some text with \\ in there ", "binary"), st.buffer
    test.deepEqual ["Some text with \\ in there"], st.values()
    test.done()

exports.StringPaddingTest =
  "test space padding": (test) ->
    test.expect 2
    lo = new vrs.LO(DEF_CTX, null, ["ASD"])
    test.deepEqual new Buffer("ASD ", "binary"), lo.buffer
    test.deepEqual ["ASD"], lo.values()
    test.done()
  "test zerobyte padding": (test) ->
    test.expect 2
    lo = new vrs.UI(DEF_CTX, null, ["1.2"])
    test.deepEqual new Buffer("1.2\x00", "binary"), lo.buffer
    test.deepEqual ["1.2"], lo.values()
    test.done()

#
# binary vrs should produce base64 encoded values ...
#
exports.OBTest =
  "test base64 values": (test) ->
    test.expect 1
    ob = new vrs.OB(DEF_CTX, new Buffer("asdf"))
    test.deepEqual ["YXNkZg=="], ob.values()
    test.done()

#
# binary vrs should produce base64 encoded values ...
#
exports.ODTest =
  "test base64 values": (test) ->
    test.expect 1
    od = new vrs.OD(DEF_CTX, new Buffer("asdfasdf"))
    test.deepEqual ["YXNkZmFzZGY="], od.values()
    test.done()

exports.PNTest =
  "test single component group value": (test) ->
    test.expect 1
    pn = new vrs.PN(DEF_CTX, new Buffer("group1"))
    test.deepEqual [{Alphabetic: "group1"}], pn.values()
    test.done()
  "test all component groups values": (test) ->
    test.expect 1
    pn = new vrs.PN(DEF_CTX, new Buffer("group1=group2=group3=x=y"))
    test.deepEqual [{Alphabetic: "group1", Ideographic: "group2", Phonetic: "group3"}], pn.values()
    test.done()
  "test encode alphabetic": (test) ->
    test.expect 1
    pn = new vrs.PN(DEF_CTX, null, [{Alphabetic: "group1"}])
    test.deepEqual new Buffer("group1"), pn.buffer
    test.done()
  "test encode all groups": (test) ->
    test.expect 1
    pn = new vrs.PN(DEF_CTX, null, [{Alphabetic: "group1", Ideographic: "group2", Phonetic: "group3", Xtra1: "x", Xtra2: "y"}])
    test.deepEqual new Buffer("group1=group2=group3"), pn.buffer
    test.done()

#
# IS and DS are encoded as strings, but represent numbers.
# They are numbers in the DICOM model.
#
exports.ISTest =
  "test values": (test) ->
    test.expect 3
    _is = new vrs.IS(DEF_CTX, new Buffer("1\\2"))
    _vals = _is.values()
    test.deepEqual [1,2], _vals
    test.equal 'number', typeof _vals[0]
    test.equal 'number', typeof _vals[1]
    test.done()
  "test encode": (test) ->
    test.expect 1
    _is = new vrs.IS(DEF_CTX, null, [1,2])
    test.deepEqual new Buffer("1\\2 "), _is.buffer
    test.done()
