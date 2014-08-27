#! /usr/bin/env coffee
#

vrs = require("./vrs")
readbuffer = require("./readbuffer")
try
  uids = require("../lib/uids.js")
  tags = require("../lib/tags.js")
catch err
  uids = require("../../lib/uids.js")
  tags = require("../../lib/tags.js")

fs = require("fs")
stream = require("stream")
bl = require("bl")
printf = require("printf")
bunyan = require("bunyan")

log = bunyan.createLogger {name: "dicom.decoder", level:'debug'}

_NO_VR_TAGS = [ tags.Item.tag, tags.ItemDelimitationItem.tag,
  tags.SequenceDelimitationItem.tag ]

##
#
# Dicom Decoder
#
# Transforms IO events into DICOM parse events
##
class Decoder extends stream.Transform
  constructor: (options)->
    super(options)
    @_writableState.objectMode = false
    @_readableState.objectMode = true
    @context = new vrs.ContextStack()
    @context.push(new vrs.Context())
    @buffer = readbuffer()

  # log summary for bunyan
  log_summary: () ->
    summary =
      buffer: @buffer.log_summary()
      context: @context.log_summary()

  _transform: (chunk, encoding, cb) ->
    @buffer.push chunk
    log.debug {buffer: @buffer.log_summary()}, "_transform"
    @_action_wrapper(@_decode_dataset)
    log.debug {buffer: @buffer.log_summary()}, "_transform done, calling cb"
    cb()

  _decode_dataset: () =>
    while obj = @_decode_dataelement()
      log.debug {event: obj.log_summary()}, "_decode_dataset: emitting"
      @emit obj

  _decode_dataelement: () =>
    @saved = @buffer.copy()
    log.debug {buffer: @saved.log_summary()}, "_decode_dataelement: saved buffer state"
    @context.handle_autopops(@start_pos)
    tag = (new vrs.AT(@context.top())).consume_value(@buffer)
    log.debug({tag: printf("%08x", tag)}, "decoded tag")
    tag_str = printf("%08X", tag)
    # comparing tags somehow does not work ...
    switch tag_str
      when tags.Item.mask
        return @_handle_item(tag)
      when tags.ItemDelimitationItem.mask
        return @_handle_itemdelimitation(tag)
      when tags.SequenceDelimitationItem.mask
        return @_handle_sequencedelimitation(tag)
      else
        return @_handle_element(tag)

  # wrap the action
  # this does the housekeeping like exception handling
  _action_wrapper: (func, args...) ->
    try
      func(args...)
    catch err
      if err?.needMoreInput
        log.debug({buffer: @buffer.log_summary()}, "_action_wrapper: need to restore")
        @buffer = @saved
        log.debug({needMoreInput: err.needMoreInput, buffer: @buffer.log_summary(), error: err},
            "_action_wrapper: restored buffer after NeedMoreInput")
      else
        log.error {error: err}, "_action_wrapper:  emitting error"
        @emit 'error', err

  _decode_datafile: () =>
    @_decode_preamble()
    @_decode_dicomheader()
    @_decode_metainfo()
    @_decode_dataset()

  _consume_std_value_length: () =>
    length_element = new vrs.UL(@context.top())
    return length_element.consume_value(@buffer)

  _handle_element: (tag) ->
    is_explicit = @context.top().explicit
    tagdef = tags.for_tag(tag)
    if not is_explicit
      vrstr = tagdef.vr
    else
      vrstr = @buffer.consume(2).toString('binary')
    log.debug {vr: vrstr}, "_handle_element"
    vr = vrs.for_name(vrstr, @context.top())
    vr.consume(@buffer, this)
    log.debug {element: tagdef.log_summary(), vr: vr.log_summary()}, "decoded element"
    return new vrs.DicomEvent(tagdef, vr)

  _handle_item: (tag) ->
    # item is always in standard ts
    value_length = @_consume_std_value_length()
    start_pos = @buffer.stream_position - 8
    if @context.top().enscapsulated
      # we are in encapsulated OB ... just stream the content out
      obj = vrs.dicom_command(tags.for_tag(tag), "start_item")
      # queue streaming and end_item
      throw new Error("implement handling encaps item")
      # self._handler.start_item(tag, start_pos, value_length)
      # vrs._stream_bytes(self._handler, self._fp, value_length)
      # self._handler.end_item(tag, start_pos, value_length)
      return obj
    else
      end_position = undefined
      if value_length != vrs.UNDEFINED_LENGTH
        end_position = @buffer.stream_position + value_length
      end_cb = () =>
        obj = vrs.dicom_command('end_item')
        log.debug {emit: obj}, "_handle_item end callback: emitting end_item"
        @emit obj
      @context.push(@context.top(), end_position, end_cb)
      obj = vrs.dicom_command(tags.for_tag(tag), 'start_item')
      return obj

  _handle_itemdelimitation: (tag) ->
    # always standard ts
    value_length = @_consume_std_value_length()
    obj = new vrs.DicomEvent(tags.for_tag(tag), null, null, 'item_delimitation')
    @context.pop()
    return obj
  _handle_sequencedelimitation: (tag) ->
    # always standard ts
    value_length = @_consume_std_value_length()
    obj = new vrs.DicomEvent(tags.for_tag(tag), null, null, 'sequence_delimitation')
    @context.pop()
    return obj

if require.main is module
  fs.createReadStream process.argv[2], {highWaterMark: 32}
  .pipe new Decoder {}

