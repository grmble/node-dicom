#! /usr/bin/env coffee

stream = require("stream")
util = require("util")
tags = require("../../lib/tags")
uids = require("../../lib/uids")
vrs = require("../../lib/vrs")
log = require("../logger")("json", "source")

##
# store queue of keys and their data
# _end is for emitting of end_item
##
class ItemEntry
  constructor: (data, @_end_event)->
    @_data = {}
    for k,v of data
      @_data[tags.for_tag(k).tag_str] = v
    @_queue = (k for k of @_data)
    @_queue.sort()
    @_queue.reverse()
  # ItemEntry unshifts strings containing 8-digit hex tag
  unshift: () ->
    return @_queue.pop()
  end_event: () ->
    return @_end_event
  data: (k) ->
    v = @_data[k]
    el = tags.for_tag(k)
    if util.isArray(v)
      v = {vr: el.vr, Value: v}
    else if typeof(v) in ['string', 'number']
      v = {vr: el.vr, Value: [v]}
    else if typeof(v) == 'object'
      if v.BulkDataURI
        throw new vrs.DicomError("can not emit json model with bulkdata uri: " + v)
      if not v.vr?
        v.vr = el.vr
    else
      throw new vrs.DicomError("can not recognize dicom json model: " + v)
    return [el, v]

## store queue of items
class SeqEntry
  constructor: (items) ->
    @_queue = (x for x in items)
    @_queue.reverse()
    log.trace({length: @_queue.length}, "SeqEntry")
  # SeqEntry unshifts json model, which pull be pushed
  # on the stack in an ItemEntry
  unshift: () ->
    return @_queue.pop()
  end_event: () ->
    return new vrs.DicomEvent(tags.SequenceDelimitationItem, null, null, "end_sequence")


##
# stack structure for traversal
##
class EmitStack
  constructor: () ->
    @_len_1 = -1
    @_stack = []
  push: (data, end_event) ->
    @_len_1++
    @_stack.push(new ItemEntry(data, end_event))
  push_seq: (items) ->
    @_len_1++
    @_stack.push(new SeqEntry(items))
  pop: () ->
    @_len_1--
    return @_stack.pop()
  top: () ->
    return @_stack[@_len_1]
  unshift: () ->
    return @top().unshift()
  data: (k) ->
    return @top().data(k)
  eof: () ->
    return @_len_1 == -1


##
#
# Emits DicomEvents for JSON Model
#
# valid options: all stream.readable options
# * transfer_syntax: transfer syntax, defaults to ExplicitVRLittleEndian
##
class JsonSource extends stream.Readable
  constructor: (data, options) ->
    if not (this instanceof JsonSource)
      return new JsonSource(data, options)
    if not options?
      options = {}
    options.objectMode = true
    super(options)
    @_stack = new EmitStack()
    @_stack.push(data, null)
    ts_name = options?.transfer_syntax
    ts_name = 'ExplicitVRLittleEndian' if not ts_name
    ts = uids.for_uid(ts_name)
    @_context = new vrs.Context({}, ts.make_context())
    log.trace({context: @_context}, "JsonSource context")
  _read: (size) ->
    try
      log.trace({size: size}, "JsonSource _read")
      read_more = true
      while read_more
        if @_stack.eof()
          log.trace "_stack eof: we are done"
          @push(null)
          read_more = false
          return
        else
          k = @_stack.unshift()
          if k?
            if typeof(k) == 'string'
              [el, v] = @_stack.data(k)
              obj = @_dicom_event(el, v)
              log.trace obj.log_summary?(), "emitting"
              read_more = @push(obj)
              if obj.command == 'start_sequence'
                log.trace v, "pushing sequence items"
                @_stack.push_seq(v.Value)
            else
              # emitting an item in a sequence
              @_stack.push(k, new vrs.DicomEvent(tags.ItemDelimitationItem, null, null, "end_item"))
              obj = new vrs.DicomEvent(tags.Item, null, null, "start_item")
              log.trace obj.log_summary?(), "emitting start item"
              read_more = @push(obj)
          else
            entry = @_stack.pop()
            obj = entry.end_event()
            if obj
              log.trace obj.log_summary?(), "emitstack end event"
              read_more = @push(obj)
      return undefined
    catch err
      @emit 'error', err

  _dicom_event: (el, v) ->
    if @_is_seq_value(v)
      if (v.vr == 'UN' || v.vr =='SQ')
        return new vrs.DicomEvent(el, vrs.for_name(v.vr, @_context), null, "start_sequence")
      else
        throw new vrs.DicomError("can not emit sequence values for vr " + v.vr + " tag " + el.tag_str)
    else
      return new vrs.DicomEvent(el, vrs.for_name(v.vr, @_context, null, v.Value), null, "element")

  _is_seq_value: (v) ->
    is_seq = true
    for _v in v.Value
      if !((typeof(_v)=='object') && !util.isArray(_v))
        is_seq = false
    return is_seq


module.exports = JsonSource


if require.main is module
  tags = require "../../lib/tags"
  data = {
    "00100020": {vr: "LO", Value: ["007"]},
    "00100021": {vr: "LO", Value: ["MI6"]},
    "00101002": {vr: "SQ", Value: [{
       "00100020": {vr: "LO", Value: ["0815"]},
       "00100021": {vr: "LO", Value: ["BND"]}}
    ]}}
  simple_data = {
    "PatientID": "007",
    "IssuerOfPatientID": "MI6",
    "OtherPatientIDsSequence": [{
      "PatientID": "0815",
      "IssuerOfPatientID": "BND"}]}
  source = new JsonSource(data)
  source.pipe process.stdout
