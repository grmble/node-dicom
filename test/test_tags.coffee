#! /usr/bin/env coffee

tags = require "../lib/tags"

exports.TagsTest =
  "test for_tag": (test) ->
    test.expect 7
    el1 = tags.for_tag(0x00100010)
    el2 = tags.for_tag('PatientName')
    el3 = tags.PatientName
    el4 = tags.for_tag(tags.PatientName)
    el5 = tags.for_tag('00100010')
    test.equal el1, el2
    test.equal el1, el3
    test.equal el1, el4
    test.equal el1, el5
    test.equal 'PatientName', el1.name
    test.equal 0x00100010, el1.tag
    test.equal 'PN', el1.vr
    test.done()

  "test private tag": (test) ->
    test.expect 4
    el = tags.for_tag(0x00090010)
    test.equal 'LO', el.vr
    el = tags.for_tag(0x000900FF)
    test.equal 'LO', el.vr
    el = tags.for_tag(0x00090100)
    test.equal 'UN', el.vr
    # private tags are only allowed in groups 9 and up
    # so there is no private tag creator of type LO
    el = tags.for_tag(0x00070010)
    test.equal 'UN', el.vr
    test.done()

  "test group length tag": (test) ->
    test.expect 1
    el = tags.for_tag(0x00090000)
    test.equal 'UL', el.vr
    test.done()

  "test masked": (test) ->
    test.expect 4
    el = tags.for_tag(0x60120010)
    test.equal el.tag, 0x60120010
    test.equal 'US', el.vr
    test.equal 'OverlayRows', el.name

    el = tags.for_tag('OverlayRows')
    test.equal 0x60000010, el.tag
    test.done()

   "test masked (unsupported)": (test) ->
     test.expect 1
     # we only support overlays/curves not the even older repeating stuff
     el = tags.for_tag(0x10002220)
     test.equal 'UN', el.vr
     test.done()
