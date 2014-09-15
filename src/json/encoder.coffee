#! /usr/bin/env coffee

stream = require("stream")
printf = require("printf")

tags = require("../../lib/tags")
log = require("../logger")("json", "encoder")

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
      @push printf('{"BulkDataURI":%s', JSON.stringify(bd_uri))
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
        @push printf('%s%s: {"vr":"%s","BulkDataURI":%s', start, key, event.vr.name, JSON.stringify(bd_uri))
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

 module.exports = JsonEncoder
