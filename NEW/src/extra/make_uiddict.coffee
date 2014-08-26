#! /usr/bin/env coffee

fs = require("fs")
printf = require("printf")
xml2js = require("xml2js")

parse_file = (fn, cb) ->
  fs.readFile fn, "utf8", (err, content) ->
    if err
      return cb err
    xml2js.parseString content, (err, x) ->
      if err
        return cb err
      cb x

_exports = []
_UID_DICT = []

err_cb = (good_cb) ->
  (err, args...) ->
    if err
      console.error("Error:", err)
      process.exit 20
    good_cb args...

collect_uid_dict = (cb) ->
  (data) ->
    for x in data.uids.uid
      uid = x.$.value
      name = x.$.keyword
      typ = x.$.type
      _exports.push "exports.#{name} = _make_uid('#{uid}', '#{name}', '#{typ}')"
      _UID_DICT.push "  '#{uid}': exports.#{name},"
    cb()

dump_dicts = () ->
  for x in _exports
    console.log x
  console.log "_UID_DICT ="
  for x in _UID_DICT
    console.log x

parse_uids = (cb) ->
  parse_file "uids.xml", collect_uid_dict(cb)

postprocess = () ->
  dump_dicts()

parse_uids err_cb () ->
  postprocess()
