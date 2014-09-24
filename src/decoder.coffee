#! /usr/bin/env coffee
#

vrs = require("./vrs")
readbuffer = require("./readbuffer")
uids = require("../lib/uids")
tags = require("../lib/tags")

fs = require("fs")
stream = require("stream")
printf = require("printf")

log = require("./logger")('decoder')

##
#
# Dicom Decoder
#
# Transforms IO events into DICOM parse events
#
# stream.Readable / stream.Writeable / Stream.Transform options are accepted
#
# also:
# * streaming_value_length_minimum: minimum value length, longer values will be
#   streamed
# * read_header: read preamble / dicom header, defaults to false.
#   Also implies reading metainfo.
# * transfer_syntax: transfer syntax, defaults to ExplicitVRLittleEndian
# * guess_header: will try to guess if preamble/dicom header are present
##
class Decoder extends stream.Transform
  constructor: (options)->
    if not (this instanceof Decoder)
      return new Decoder(options)
    super(options)
    @streaming_value_length_minimum = options?.streaming_value_length_minimum
    @_writableState.objectMode = false
    @_readableState.objectMode = true
    @context = new vrs.ContextStack()
    ts_name = options?.transfer_syntax
    ts_name = 'ExplicitVRLittleEndian' if not ts_name
    ts = uids.for_uid(ts_name)
    @context.push(ts.make_context())
    @buffer = readbuffer()
    if options?.read_header
      log.debug "initial state: read_header"
      @state = @_decode_datafile
    else if options?.guess_header
      log.debug "initial state: guess_header"
      @state = @_guess_header
    else
      log.debug "initial state: decode_dataset"
      @state = @_decode_dataset
    log.debug({decoder: @log_summary()}, "decoder initialized")

  # log summary for bunyan
  log_summary: () ->
    summary =
      buffer: @buffer.log_summary()
      context: @context.log_summary()

  _transform: (chunk, encoding, cb) ->
    @buffer.push chunk
    log.debug({buffer: @buffer.log_summary()}, "_transform") if log.debug()
    @_action_wrapper(@state)
    log.debug({buffer: @buffer.log_summary()}, "_transform done, calling cb") if log.debug()
    cb()

  _flush: (cb) ->
    @_action_wrapper(@state)
    if @buffer.length == 0 and @context.stack_depth() == 1 and @saved.stream_position == @buffer.stream_position
      log.debug "_flush successful, all is well with our decode"
      cb()
    else
      log.debug({buffer: @buffer.length, context: @context.stack_depth(), saved: @saved.stream_position, position: @buffer.stream_position},
        "_flush: can not flush (length should be 0, stack depth 1)")
      @emit('error',  new vrs.UnexpectedEofOfFile())

  _switch_state: (state, msg) ->
    if not state
      state = @_decode_dataset
    log.debug {state: state}, "switching state: #{msg} ==> #{state}"
    @state = state

  _decode_metainfo: () =>
    if not @metainfo_length
      @saved = @buffer.copy()
      start_pos = @buffer.stream_position
      @metainfo_done = false

      metainfo_cb = () =>
        log.debug "metainfo callback, setting metainfo_done"
        @metainfo_done = true
        @_switch_state @_decode_dataset, "metainfo done, decoding dataset"
        if @metainfo_listener
          log.debug "asdf"
          @removeListener 'data', @metainfo_listener
          @metainfo_listener = undefined
          log.debug "jkl"
        log.debug "ts=#{@metainfo_ts}"
        ts = uids.for_uid(@metainfo_ts)
        log.debug {ts: ts}, "_decode_metainfo: switching transfer syntax"
        @context.replace_root(ts.make_context())

      @metainfo_listener = (event) =>
        if event.element.tag == 0x00020010
          @metainfo_ts = event.vr.value()
          log.debug {ts: @metainfo_ts}, "metainfo transfer syntax found"
        else if event.element.tag == 0x00020000
          @metainfo_length = event.vr.value()
          log.debug {length: @metainfo_length}, "metainfo length found"
          @context.push({}, start_pos + @metainfo_length, metainfo_cb)
      @on 'data', @metainfo_listener

    while not @metainfo_done
      @_decode_dataelement()
    log.debug("breaking out of metainfo loop")

    @_decode_dataset()

  _decode_dataset: () =>
    while true
      @_decode_dataelement()
    return undefined


  _decode_dataelement: () =>
    @saved = @buffer.copy()
    log.trace({buffer: @saved.log_summary()}, "_decode_dataelement: saved buffer state") if log.trace()
    element_position = @buffer.stream_position
    @context.handle_autopops(element_position)
    tag = (new vrs.AT(@context.top())).consume_value(@buffer)
    log.debug({tag: printf("%08x", tag)}, "decoded tag") if log.debug()
    tag_str = printf("%08X", tag)
    # comparing tags somehow does not work ...
    switch tag_str
      when tags.Item.mask
        @_handle_item(tag, element_position)
      when tags.ItemDelimitationItem.mask
        @_handle_itemdelimitation(tag, element_position)
      when tags.SequenceDelimitationItem.mask
        @_handle_sequencedelimitation(tag, element_position)
      else
        @_handle_element(tag, element_position)

  # wrap the action
  # this does the housekeeping like exception handling
  _action_wrapper: (func) ->
    try
      func()
    catch err
      if err?.doNotRestore
        log.debug "_action_wrapper: streaming NeedMoreInput - no need to restore"
        # @saved = @buffer ???
      else if err?.needMoreInput
        log.debug({buffer: @buffer.log_summary()}, "_action_wrapper: need to restore")
        @buffer = @saved
        log.debug({needMoreInput: err.needMoreInput, buffer: @buffer.log_summary(), error: err},
          "_action_wrapper: restored buffer after NeedMoreInput")
      else
        log.error {error: err}, "_action_wrapper:  emitting error"
        @emit 'error', err

  ## 
  # try to guess the format
  # DICM at offset 128+ => header present
  # file starts with: 0800 0500 4353 ==> SpecificCharacterSet, ExplicitVRLittleEndian
  # file starts with: 0800 0500  ==> SpecificCharacterSet, ImplicitVRLittleEndian
  _guess_header: () =>
    @saved = @buffer.copy()
    header = @buffer.easy_consume(132)
    if header.length == 132 and header.toString("binary", 128, 132) == 'DICM'
      log.debug "_guess_header: dicom header present, reading dicom datafile"
      @buffer = @saved
      return @_decode_datafile()
    if header.length >= 6 and header.slice(0, 6).equals(new Buffer([0x08, 0x00, 0x05, 0x00, 0x43, 0x53]))
      log.debug "_guess_header: start with specific character set, ExplicitVRLittleEndian"
      @buffer = @saved
      return @_decode_dataset()
    if header.length >= 4 and header.slice(0, 4).equals(new Buffer([0x08, 0x00, 0x05, 0x00]))
      log.debug "_guess_header: start with specific character set, ImplicitVRLittleEndian"
      ts = uids.for_uid('ImplicitVRLittleEndian')
      @context.replace_root(ts.make_context())
      @buffer = @saved
      return @_decode_dataset()
    throw new vrs.DicomError("Unable to guess DICOM encoding")
    
  _decode_datafile: () =>
    @_switch_state @_decode_datafile, "decoding preamble/header"
    @saved = @buffer.copy()
    header = @buffer.consume(132)
    if header.toString("binary", 128, 132) != 'DICM'
      throw new vrs.DicomError("No DICOM header found")
    @_switch_state @_decode_metainfo, "header decoded, decoding metainfo now"
    @_decode_metainfo()

  _consume_std_value_length: () =>
    length_element = new vrs.UL(@context.top_little_endian())
    return length_element.consume_value(@buffer)

  _handle_element: (tag, start_position) ->
    is_explicit = @context.top().explicit
    tagdef = tags.for_tag(tag)
    if not is_explicit
      vrstr = tagdef.vr
    else
      vrstr = @buffer.consume(2).toString('binary')
    log.debug({vr: vrstr}, "_handle_element") if log.debug()
    vr = vrs.for_name(vrstr, @context.top())
    vr.consume_and_emit(tagdef, @buffer, this, start_position)

  _handle_item: (tag, start_pos) ->
    # item is always in standard ts
    value_length = @_consume_std_value_length()
    element = tags.for_tag(tag)
    if @context.top().encapsulated
      # we are in encapsulated OB ... just stream the content out
      bd_offset = @buffer.stream_position
      bd_length = value_length
      obj = new vrs.DicomEvent(element, null, start_pos, "start_item", null, bd_offset, bd_length)
      @log_and_push obj
      _obj = new vrs.DicomEvent(element, null, start_pos, "end_item", null, bd_offset, bd_length)
      @_stream_bytes(value_length, _obj)
      return undefined # no emit by main loop, thank you
    else
      end_position = undefined
      if value_length != vrs.UNDEFINED_LENGTH
        end_position = @buffer.stream_position + value_length
      end_cb = () =>
        _obj = new vrs.DicomEvent(element, null, start_pos, "end_item")
        @log_and_push _obj
      @context.push({}, end_position, end_cb)
      obj = new vrs.DicomEvent(element, null, start_pos, "start_item")
      @log_and_push obj

  _handle_itemdelimitation: (tag, start_position) ->
    # always standard ts
    value_length = @_consume_std_value_length()
    obj = new vrs.DicomEvent(tags.for_tag(tag), null, start_position, 'end_item')
    @context.pop()
    @log_and_push obj

  _handle_sequencedelimitation: (tag, start_position) ->
    # always standard ts
    value_length = @_consume_std_value_length()
    command = 'end_sequence'
    popped = @context.pop()
    if popped?.encapsulated and not @context.top().encapsulated
      # we were inside encapsulated pixeldata - SequenceDelimitationItem
      # ends the pixeldata element, not some sequence
      command = 'end_element'
    obj = new vrs.DicomEvent(tags.for_tag(tag), null, start_position, command)
    @log_and_push obj

  # stream x bytes out
  # this switches states to itself in case the buffer
  # runs short (very likely with streaming).
  # once all bytes have been consumed/emitted,
  # emitObj will be emitted (if any).
  # Finally the state will be switched to nextState.
  # nextState defaults to _decode_dataset
  _stream_bytes: (bytes, emitObj, nextState) ->
    log.debug "_stream_bytes: arranging to stream #{bytes}"
    streamer = new ByteStreamer({bytes: bytes, emitObj:emitObj, nextState: nextState, buffer: @buffer, decoder: this})
    @_switch_state streamer.stream_bytes, "byte_streamer_state"
    streamer.stream_bytes()

  log_and_push: (obj) ->
    log.debug({event: obj.log_summary?()}, "Decoder: emitting dicom event") if log.debug()
    @push obj

class ByteStreamer
  constructor: (options) ->
    {@bytes,@emitObj,@nextState,@buffer,@decoder} = options
  stream_bytes: () =>
    while @bytes > 0
      buff = @buffer.easy_consume(@bytes)
      @bytes -= buff.length
      obj = new vrs.DicomEvent(undefined, undefined, undefined, undefined, buff)
      @decoder.log_and_push obj
    if @emitObj?
      @decoder.log_and_push @emitObj
    if not @nextState?
      @nextState = @decoder.decode_dataset
    @decoder._switch_state(@nextState, "stream_bytes nextState")

module.exports = Decoder

if require.main is module
  fs.createReadStream process.argv[2] #, {highWaterMark: 32}
  .pipe new Decoder {guess_header: true}

