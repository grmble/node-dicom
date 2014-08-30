#! /usr/bin/env coffee

uids = require "../lib/uids"
vrs = require "../lib/vrs"

exports.TagsTest =
  "test default ts": (test) ->
    test.expect 4
    dts = uids.ImplicitVRLittleEndian
    test.equal uids.ImplicitVRLittleEndian.uid, dts.uid
    test.equal 'ImplicitVRLittleEndian', dts.name
    test.deepEqual vrs.LITTLE_ENDIAN, dts.endianess()
    test.equal false, dts.is_explicit()
    test.done()

  "test for_uid": (test) ->
    test.expect 2
    dts = uids.for_uid(uids.ImplicitVRLittleEndian.uid)
    test.equal uids.ImplicitVRLittleEndian, dts
    dts = uids.for_uid('ImplicitVRLittleEndian')
    test.equal uids.ImplicitVRLittleEndian, dts
    test.done()
