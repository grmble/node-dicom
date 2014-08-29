#! /usr/bin/env coffee

##
#
# DICOM Json Model
#
# http://medical.nema.org/dicom/2013/output/chtml/part18/sect_F.2.html
#
##

stream = require("stream")
printf = require("printf")
ConcatStream = require("concat-stream")

log = require("./logger")("json")

##
# JsonEncoder
#
# takes a stream of DicomEvents and produces
# JSON.
#
# at the moment, this simply
# ignores start_element/raw/end_element
# i.e. bulk data (= data where the length
# exceeds the decoder option) is ignored
##
class JsonEncoder extends stream.Transform
  constructor: (options)->
    if not (this instanceof JsonEncoder)
      return new JsonEncoder(options)
    super(options)
    @_writableState.objectMode = true
    @_readableState.objectMode = false
    @depth = 0
    @fresh = true
    @ignore = 0

  _transform: (event, encoding, cb) ->
    try
      log.trace event.log_summary(), "Json:_transform received dicom event"
      command = event.command
      switch command
        when 'element' then @handle_element(event)
        when 'start_sequence' then @start_sequence(event)
        when 'end_sequence' then @end_sequence(event)
        when 'start_item' then @start_item(event)
        when 'end_item' then @end_item(event)
        when 'start_element' then @start_element(event)
        when 'end_element' then @end_element(event)
        else
          log.trace {command: command}, "_transform: ignoring"
      cb(null)
    catch err
      log.error err
      cb(err)

  _flush: (cb) ->
    @push "}"
    cb(null)


  handle_element: (event) ->
    return if @ignore
    key = printf '"%08X"', event.element.tag
    key = printf "%*s", key, key.length + @depth
    obj =
      vr: event.element.vr,
      Value: event.vr.values()
    start = ',\n'
    if @fresh
      start = '{\n'
      @fresh = false
    @push printf('%s%s: %s', start, key, JSON.stringify(obj))

  start_sequence: (event) ->
    return if @ignore
    key = printf '"%08X"', event.element.tag
    key = printf "%*s", key, key.length + @depth
    start = ',\n'
    if @fresh
      start = '{\n'
    @push printf('%s%s: {"vr": "SQ", "Value": [', start, key)
    @fresh = true
    @depth++

  end_sequence: (event) ->
    return if @ignore
    @fresh = false
    @push ']}'
    @depth--

  start_item: (event) ->
    return if @ignore
    # will trigger { on next element
    if not @fresh
      @push ","
    @fresh = true
  end_item: (event) ->
    return if @ignore
    if @fresh
      @push "{}"
    else
      @push "}"

  # ignore everything inside start_element / end_element
  start_element: (event) ->
    @ignore++
  end_element: (event) ->
    @ignore--

##
#
# Calls cb with JSON or error
##
class JsonSink extends ConcatStream
  constructor: (cb) ->
    super {}, (json_string) ->
      try
        json = JSON.parse(json_string)
        cb null, json
      catch err
        cb(err)
      undefined
    @on 'error', (err) ->
      cb(err)
      
exports.JsonEncoder = JsonEncoder
exports.JsonSink = JsonSink

if require.main is module
  log.debug "JSONifying #{process.argv[2]}"
  decoder = require("./decoder") {guess_header: true}
  encoder = new JsonEncoder()
  sink = new JsonSink (err, json) ->
    console.log("Error:", err, "JSON:", json)
  require("fs").createReadStream(process.argv[2]).pipe decoder
  decoder.pipe encoder
  # encoder.pipe sink
  encoder.pipe process.stdout


