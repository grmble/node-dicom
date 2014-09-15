#! /usr/bin/env coffee
#

vrs = require("../lib/vrs")
uids = require("../lib/uids")
tags = require("../lib/tags")
stream = require("stream")
printf = require("printf")

log = require("./logger")('encoder')

##
#
# Dicom Encoder
#
# Transforms DICOM Events into IO events
#
# stream.Readable / stream.Writeable / Stream.Transform options are accepted
#
# also:
# * transfer_syntax: transfer syntax, defaults to ExplicitVRLittleEndian
##
class Encoder extends stream.Transform
  constructor: (options)->
    if not (this instanceof Encoder)
      return new Encoder(options)
    super(options)
    @_writableState.objectMode = true
    @_readableState.objectMode = false
    @context = new vrs.ContextStack()
    ts_name = options?.transfer_syntax
    ts_name = 'ExplicitVRLittleEndian' if not ts_name
    ts = uids.for_uid(ts_name)
    @context.push(ts.make_context())
    log.debug({encoder: @log_summary()}, "encoder initialized")
  
  _transform: (obj, encoding, cb) ->
    try
      log.trace(obj?.log_summary?(), "Encoder _transform") if log.trace()
      switch obj.command
        when 'element'
          obj.vr._encode_and_emit(obj.element, this)
        when 'start_sequence'
          obj.vr._encode_and_emit_seq(obj.element, this)
        when 'end_sequence'
          @_emit_std_tag_and_value_length(tags.SequenceDelimitationItem.tag, 0)
        when 'start_item'
          @_emit_std_tag_and_value_length(tags.Item.tag, vrs.UNDEFINED_LENGTH)
        when 'end_item'
          @_emit_std_tag_and_value_length(tags.ItemDelimitationItem.tag, 0)
        when 'start_element'
          @_handle_start_element(obj)
        when 'end_element'
          @_handle_end_element(obj)
        else
          @_handle_raw(obj)
      return cb()
    catch err
      @emit 'error', err

  # emit item, item_delimitation and sequence delimitation
  # these are always in implicitvrle
  _emit_std_tag_and_value_length: (tag, value_length) ->
    tag = new vrs.AT(@context.top(), null, [tag])
    log.trace({tag: tag, value_length: value_length}, "_emit_std_element_and_value_length")
    @push(tag.buffer)
    ul = new vrs.UL(@context.top_little_endian(), null, [value_length])
    @push(ul.buffer)



  # log summary for bunyan
  log_summary: () ->
    summary =
      context: @context.log_summary()

module.exports = Encoder

err_cb = (err) ->
  console.error "Error:", err
  console.error "Stack trace:", err.stack
  process.exit 10

if require.main is module
  fs = require "fs"
  sink = require "./json/sink"
  source = require "./json/source"
  fs.createReadStream process.argv[2]
  .pipe sink (err, data) ->
    return err_cb(err) if err
    log.trace {json: data}, "Processing JSON:"
    source data
    .on 'error', err_cb
    .pipe new Encoder()
    .on 'error', err_cb
    .pipe fs.createWriteStream process.argv[3] || "/tmp/x.x"
    .on 'error', err_cb



