#! /usr/bin/env coffee

ConcatStream = require("concat-stream")
log = require("../logger")("json", "sink")

##
#
# Calls cb with JSON or error
##
class JsonSink extends ConcatStream
  constructor: (cb) ->
    if not (this instanceof JsonSink)
      return new JsonSink(cb)
    super {}, (json_string) ->
      try
        json = JSON.parse(json_string)
        cb null, json
      catch err
        cb(err)
      undefined
    @on 'error', (err) ->
      log.debug {error: err}, "JsonSink: on error ... calling cb"
      cb(err)

module.exports = JsonSink
