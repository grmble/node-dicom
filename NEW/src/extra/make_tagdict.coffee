#! /usr/bin/env coffee

fs = require("fs")
printf = require("printf")
xml2js = require("xml2js")
tags = require("../lib/tags")

parse_file = (fn, cb) ->
  fs.readFile fn, "utf8", (err, content) ->
    if err
      return cb err
    xml2js.parseString content, (err, x) ->
      if err
        return cb err
      cb x

_TAG_DICT = []
_TAGNAME_DICT = []
_masks = []
_TAG_MASKS = []

err_cb = (good_cb) ->
  (err, args...) ->
    if err
      console.error("Error:", err)
      process.exit 20
    good_cb args...

collect_tag_dict = (root, cb) ->
  (data) ->
    console.log "# collect tag_dict #{root}"
    for x in data[root].el
      mask = x.$.tag
      xxx = mask.replace(/[xX]/g, '0')
      tag = parseInt(xxx, 16)
      tag_str = printf "%08x", tag
      _TAG_DICT.push "  '#{tag_str}': new Element(#{tag}, '#{x.$.keyword}', '#{x.$.vr}', '#{x.$.vm}', '#{mask}', #{x.$.retired}),"
      _TAGNAME_DICT.push "  '#{x.$.keyword}': _TAG_DICT['#{tag_str}'],"
      if 'x' in mask
        _masks.push mask
    cb()

calc_masks = () ->
  for [cnt, and_mask, base_tag] in tags.calc_bitmasks(_masks)
    _TAG_MASKS.push printf("   [%d, 0x%08x, 0x%08x],", cnt, and_mask, base_tag)

dump_dicts = () ->
  console.log "_TAG_DICT ="
  for x in _TAG_DICT
    console.log x
  console.log "_TAGNAME_DICT ="
  for x in _TAGNAME_DICT
    console.log x
  console.log "_TAG_MASKS = ["
  for x in _TAG_MASKS
    console.log x
  console.log "]"

parse_commandelements = (cb) ->
  parse_file "commandelements.xml", collect_tag_dict("commandelements", cb)
parse_dataelements = (cb) ->
  parse_file "dataelements.xml", collect_tag_dict("dataelements", cb)

postprocess = () ->
  console.log("# postprocessing")
  calc_masks()
  dump_dicts()

parse_commandelements err_cb () ->
  parse_dataelements err_cb () ->
    postprocess()
