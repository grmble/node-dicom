#! /usr/bin/env coffee

##
#
# DICOM Json Model
#
# http://medical.nema.org/dicom/2013/output/chtml/part18/sect_F.2.html
#
##

fs = require("fs")
stream = require("stream")
zlib = require("zlib")

printf = require("printf")
ConcatStream = require("concat-stream")

tags = require("../lib/tags")
decoder = require("../lib/decoder")
log = require("./logger")("json")

##
# JsonEncoder
#
# takes a stream of DicomEvents and produces
# JSON.
#
# * bulkdata_uri: uri for emitting bulkdata - ?offset=x&length=y will be appended
##
class JsonEncoder extends stream.Transform
  constructor: (options)->
    if not (this instanceof JsonEncoder)
      return new JsonEncoder(options)
    super(options)
    @_bulkdata_uri = options?.bulkdata_uri
    @_writableState.objectMode = true
    @_readableState.objectMode = false
    @depth = 0
    @fresh = true
    @ignore = 0

  _transform: (event, encoding, cb) ->
    try
      log.debug({command: event.command, element: event.element?.name, depth: @depth},
        "Json:_transform received dicom event") if log.debug()
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
          log.trace({command: command}, "_transform: ignoring") if log.trace()
      cb(null)
    catch err
      log.error err
      cb(err)

  _flush: (cb) ->
    @push "}\n"
    cb(null)


  handle_element: (event) ->
    return if @ignore
    key = printf '"%08X"', event.element.tag
    key = printf "%*s", key, key.length + @depth
    obj = {vr: event.vr.name}
    if event.vr.base64_values
      obj.InlineBinary = event.vr.values()
    else
      obj.Value = event.vr.values()
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
    @push printf('%s%s: {"vr":"SQ", "Value": [', start, key)
    @fresh = true
    @depth++

  end_sequence: (event) ->
    return if @ignore
    @fresh = false
    @push ']}'
    @depth--

  start_item: (event) ->
    return if @ignore
    if not @fresh
      @push ","
    @fresh = true
    if event.bulkdata_offset and event.bulkdata_length
      # encapsulated pixeldata
      bd_uri = @_bulkdata_uri + "?offset=" + event.bulkdata_offset + "&length=" + event.bulkdata_length
      @push printf('{"BulkDataURI":"%s"', bd_uri)
      @fresh = false

  end_item: (event) ->
    return if @ignore
    if @fresh
      @push "{}"
    else
      @push "}"
    @fresh = false

  # ignore everything inside start_element / end_element
  start_element: (event) ->
    if @_bulkdata_uri
      key = printf '"%08X"', event.element.tag
      key = printf "%*s", key, key.length + @depth
      start = ',\n'
      if @fresh
        start = '{\n'
      if event.bulkdata_offset and event.bulkdata_length
        bd_uri = @_bulkdata_uri + "?offset=" + event.bulkdata_offset + "&length=" + event.bulkdata_length
        @push printf('%s%s: {"vr":"%s","BulkDataURI":"%s"', start, key, event.vr.name, bd_uri)
      else
        @push printf('%s%s: {"vr":"%s","DataFragment": [', start, key, event.vr.name)
      @fresh = true
      @depth++
    else
      @ignore++

  end_element: (event) ->
    if @ignore
      @ignore--
      return
    if @_bulkdata_uri
      @fresh = false
      if event.bulkdata_offset and event.bulkdata_length
        @push '}'
      else
        @push ']}'
      @depth--

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
      log.debug {error: err}, "JsonSink: on error ... calling cb"
      cb(err)
      
exports.JsonEncoder = JsonEncoder
exports.JsonSink = JsonSink

# helper functions
# path elements may be anything that can be
# tags.for_tag-ed except NUBMERS - they
# represent sequence item access
get_element = (json, path...) ->
  lookup = []
  must_pop = false
  for p in path
    if (typeof p) == 'number'
      lookup.push p
      must_pop = false
    else
      lookup.push tags.for_tag(p).tag_str
      lookup.push "Value"
      must_pop = true
  if must_pop
    lookup.pop()
  result = json
  for x in lookup
    result = result?[x]
  return result

get_values = (json, path...) ->
  return get_element(json, path...)?.Value

get_value = (json, path...) ->
  return get_values(json, path...)?[0]

get_vr = (json, path...) ->
  return get_element(json, path...)?.vr

file2jsonstream = (fn, cb) ->
  fs.createReadStream fn
  .on 'error', cb
  .pipe decoder {guess_header: true}
  .on 'error', cb
  .pipe new JsonEncoder({bulkdata_uri: fn})
  .on 'error', cb

file2json = (fn, cb) ->
  file2jsonstream(fn, cb)
  .pipe new JsonSink(cb)
  .on 'error', cb

# cb is called for errors
gunzip2jsonstream = (fn, cb) ->
  fs.createReadStream fn
  .on 'error', cb
  .pipe zlib.createGunzip()
  .on 'error', cb
  .pipe decoder {guess_header: true}
  .on 'error', cb
  .pipe new JsonEncoder({bulkdata_uri: fn})
  .on 'error', cb

gunzip2json = (fn, cb) ->
  gunzip2jsonstream(fn, cb)
  .pipe new JsonSink(cb)
  .on 'error', cb

exports.get_element = get_element
exports.get_values = get_values
exports.get_value = get_value
exports.get_vr = get_vr
exports.file2jsonstream = file2jsonstream
exports.gunzip2jsonstream = gunzip2jsonstream
exports.file2json = file2json
exports.gunzip2json = gunzip2json


_err_cb = (err) ->
  console.error "Error:", err.stack
  process.exit 1

if require.main is module
  compressed = false
  if process.argv[2] == "-z"
    compressed = true
    filename = process.argv[3]
  else
    filename = process.argv[2]
  if compressed
    input = gunzip2jsonstream(filename, _err_cb)
  else
    input = file2jsonstream(filename, _err_cb)
  input.pipe process.stdout

