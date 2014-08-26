#! /usr/bin/env coffee

# importing the compiled-to-js version is fast
# importing coffeescript datadict is slow
# we don't like slow
try
  uids = require "../lib/uids.js"
catch err
  uids = require "../../lib/uids.js"
vrs = require "../lib/vrs"

exports.TagsTest =
  "test default ts": (test) ->
    test.expect 4
    dts = uids.ImplicitVRLittleEndian
    test.equal uids.ImplicitVRLittleEndian.uid, dts.uid
    test.equal 'ImplicitVRLittleEndian', dts.name
    test.deepEqual vrs.LITTLE_ENDIAN, dts.endianess()
    test.equal true, dts.is_explicit()
    test.done()

  "test for_uid": (test) ->
    test.expect 2
    dts = uids.for_uid(uids.ImplicitVRLittleEndian.uid)
    test.equal uids.ImplicitVRLittleEndian, dts
    dts = uids.for_uid('ImplicitVRLittleEndian')
    test.equal uids.ImplicitVRLittleEndian, dts
    test.done()
