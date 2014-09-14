#! /usr/bin/env coffee

stream = require("stream")
log = require("../logger")("json", "source")

##
#
# Emits DicomEvents for JSON Model
##
class JsonSource extends stream.Readable
  constructor: (data, options) ->
    if not (this instanceof JsonSource)
      return new JsonSink(data, options)
    if not options?
      options = {}
    options.objectMode = true
    super(options)
  _read: (size) ->
    log.debug({size: size}, "JsonSource _read")

module.exports = JsonSource
