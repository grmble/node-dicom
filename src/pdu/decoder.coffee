#! /usr/bin/env coffee

stream = require("stream")
printf = require("printf")
readbuffer = require("../readbuffer")
vrs = require("../../lib/vrs")

log = require("../logger")('pdu', 'decoder')

##
# PDUDecoder
#
# Tranform-Stream reading from a socket
# and emitting Dicom PDU events
##
class PDUDecoder extends stream.Transform
  constructor: (options)->
    if not (this instanceof PDUDecoder)
      return new PDUDecoder(options)
    super(options)
    @_writableState.objectMode = false
    @_readableState.objectMode = true
    @__buffer = readbuffer()
    @__saved = @__buffer.copy()

  _transform: (chunk, encoding, cb) ->
    @__buffer.push chunk
    log.debug({buffer: @__buffer.log_summary()}, "_transform") if log.debug()
    @__consume_pdu()
    log.debug({buffer: @__buffer.log_summary()}, "_transform done, calling cb") if log.debug()
    cb()

  _flush: (cb) ->
    log.debug("_flush")
    cb()

  __consume_pdu: () ->
    try
      @__saved = @__buffer.copy()
      __header = @__buffer.consume(6)
      __type = __header[0]
      __length = __header.readUInt32BE(2)
      __pdubuff = @__buffer.consume(__length)
      __pdu = @__decode_pdu(__type, __length, __pdubuff)
      log.trace({pdu: __pdu}, "__consume_pdu")
      # log.trace({header: __header, pdubuff: __pdubuff}, "pdu buffers")
      @push(__pdu)
    catch err
      if err?.needMoreInput
        @__buffer = @__saved
        log.debug({needMoreInput: err.needMoreInput, buffer: @buffer.log_summary(), error: err},
          "_action_wrapper: restored buffer after NeedMoreInput")
      else
        log.error({error: err}, "__consume_pdu: error")
        @emit 'error', err

  __decode_pdu: (type, length, pdubuff) ->
    switch type
      when 0x01 then return @__decode_assoc_rq_pdu(type, length, pdubuff)
      else
        throw new vrs.DicomError("Unrecognized PDU: #{type}")

  __decode_assoc_rq_pdu: (type, length, pdubuff) ->
    __assoc_rq =
      pdu_type: type
      _pdu_length: length
      # standard position - 7
      protocol_version: pdubuff.readUInt16BE(0)
      called_aet_title: pdubuff.slice(4, 20).toString().trim()
      calling_aet_title: pdubuff.slice(20, 36).toString().trim()
    return @__decode_var_items(__assoc_rq, pdubuff, 68, __assoc_rq._pdu_length, {'application_context': 1, 'presentation_context': -1, 'user_information': 1})

  __decode_var_items: (pdu, pdubuff, offset, end_offset, item_counts) ->
    log.trace({offset: offset, end: end_offset}, "__decode_var_items") if log.trace()
    if offset >= end_offset
      return pdu
    __item = @__decode_item(pdubuff, offset)
    __name = item_name(__item)
    __cnt = item_counts[__name]
    if __cnt == 1
      if pdu[__name]
        throw new vrs.DicomError("Only one #{__name} allowed")
      else
        pdu[__name] = __item
    else
      if not pdu[__name]?
        pdu[__name] = []
      pdu[__name].push __item
    return @__decode_var_items(pdu, pdubuff, offset + __item._item_length + 4, end_offset, item_counts)

  __decode_item: (pdubuff, offset) ->
    __item =
      item_type: pdubuff[offset]
      _item_length: pdubuff.readUInt16BE(offset + 2)
      _item_offset: offset
    switch __item.item_type
      when 0x10 then @__decode_application_context_item(__item, pdubuff, offset)
      when 0x20 then @__decode_presentation_context_item(__item, pdubuff, offset)
      when 0x30 then @__decode_abstract_syntax_item(__item, pdubuff, offset)
      when 0x40 then @__decode_transfer_syntax_item(__item, pdubuff, offset)
      when 0x50 then @__decode_user_information_item(__item, pdubuff, offset)
      when 0x51 then @__decode_maximum_length_item(__item, pdubuff, offset)
      when 0x52 then @__decode_implementation_class_uid_item(__item, pdubuff, offset)
      when 0x53 then @__decode_asynchronous_operations_window_item(__item, pdubuff, offset)
      when 0x53 then @__decode_scp_scu_role_selection_item(__item, pdubuff, offset)
      when 0x55 then @__decode_implementation_version_name_item(__item, pdubuff, offset)
      else
        log.warn(type: printf("%02X", __item.item_type), "PDU item not implemented")
    log.trace({item: printf("%02X", __item.item_type), offset: offset}, "__decode_item: decoded item") if log.trace()
    return __item

  __decode_application_context_item: (item, pdubuff, offset) ->
    item.application_context_name = ui_str(item, pdubuff, offset, 4)
    return item

  __decode_presentation_context_item: (item, pdubuff, offset) ->
    item.presentation_context_id = pdubuff[offset + 4]
    @__decode_var_items(item,  pdubuff, offset + 8, offset + 4 + item._item_length, {'abstract_syntax': 1, 'transfer_syntax': -1})
    return item

  __decode_abstract_syntax_item: (item, pdubuff, offset) ->
    item.abstract_syntax_name = ui_str(item, pdubuff, offset, 4)
    return item

  __decode_transfer_syntax_item: (item, pdubuff, offset) ->
    item.transfer_syntax_name = ui_str(item, pdubuff, offset, 4)
    return item

  __decode_user_information_item: (item, pdubuff, offset) ->
    @__decode_var_items(item, pdubuff, offset + 4, offset + 4 + item._item_length, {'maximum_length': 1})
    return item

  __decode_maximum_length_item: (item, pdubuff, offset) ->
    item.maximum_length_received = pdubuff.readUInt32BE(offset + 4)
    return item

  __decode_implementation_class_uid_item: (item, pdubuff, offset) ->
    item.implementation_class_uid = ui_str(item, pdubuff, offset, 4)
    return item
  __decode_implementation_version_name_item: (item, pdubuff, offset) ->
    item.implementation_version_name = ui_str(item, pdubuff, offset, 4)
    return item
  __decode_asynchronous_operations_window_item: (item, pdubuff, offset) ->
    item.maximum_number_operations_invoked = pdubuff.readUInt16BE(offset + 4)
    item.maximum_number_operations_performed = pdubuff.readUInt16BE(offset + 6)
    return item
  __decode_scp_scu_role_selection_item: (item, pdubuff, offset) ->
    item.uid_length = pdubuff.readUInt16BE(offset + 4)
    _start = offset + 6
    _end = offset + 6 + item.uid_length
    _uid = pdubuff.toString('binary', _start, _end)
    item.sop_class_uid = trim_ui(_uid)
    item.scu_role = pdubuff[_end]
    item.scp_role = pdubuff[_end + 1]
    return item


ui_str = (item, buffer, offset, item_offset) ->
  _start = offset + item_offset
  _end = offset + item_offset + item._item_length
  # log.trace({start: _start, end: _end}, "ui_str") if log.trace()
  return trim_ui(buffer.toString('binary', _start, _end))

trim_ui = (str) ->
  _len = str.length
  if _len > 0 and str[_len - 1] == '\x00'
    str.slice(0, -1)
  else
    str

ITEM_NAMES =
  '10': 'application_context'
  '20': 'presentation_context'
  '30': 'abstract_syntax'
  '40': 'transfer_syntax'
  '50': 'user_information'
  '51': 'maximum_length'
  '52': 'implementation_class_uid'
  '53': 'asynchronous_operations_window'
  '54': 'scp_scu_role_selection'
  '55': 'implementation_version_name'

item_name = (item) ->
  _hex = printf("%02X", item.item_type)
  return ITEM_NAMES[_hex]

module.exports = PDUDecoder


if require.main is module
  net = require "net"
  server = net.createServer {}, (conn) ->
    log.info "connection"
    conn.on 'end', () ->
      log.info "connection end"
    conn.pipe new PDUDecoder()
  server.listen 11112, () ->
    log.info "server bound to port 11112"
