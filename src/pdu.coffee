#! /usr/bin/env coffee

stream = require("stream")
printf = require("printf")
readbuffer = require("./readbuffer")
vrs = require("../lib/vrs")

log = require("./logger")('pdu', 'decoder')

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
      __constr = pdu_constructor(__type)
      if not __constr?
        throw new vrs.DicomError("Unrecognized PDU: #{__type}")
      __pdu = new __constr(__pdubuff)
      log.trace({pdu: __pdu}, "__consume_pdu")
      # log.trace({header: __header, pdubuff: __pdubuff}, "pdu buffers")
      @push(__pdu)
    catch err
      if err?.needMoreInput
        @__buffer = @__saved
        log.debug({needMoreInput: err.needMoreInput, buffer: @__buffer.log_summary(), error: err},
          "_action_wrapper: restored buffer after NeedMoreInput")
      else
        log.error({error: err}, "__consume_pdu: error")
        @emit 'error', err


class PDU
  _json_name: true

  constructor: (@_buff) ->
    @decode()
    delete @_buff

  decode_var_items: (start, end) ->
    log.trace({start: start, end: end}, "PDU.decode_var_items") if log.trace()
    while start < end
      log.trace({start: start, end: end}, "PDU.decode_var_items") if log.trace()
      _item = @decode_item(start)
      _name = _item.name
      _cnt = @var_item_counts[_name]
      if _cnt is 1
        if this[_name]
          throw new vrs.DicomError("Only one #{_name} allowed")
        else
          this[_name] = _item
      else
        if not this[_name]?
          this[_name] = []
        this[_name].push _item
      start = _item._end
    return undefined

  decode_item: (start) ->
    _type = @_buff[start]
    _length = @_buff.readUInt16BE(start + 2)
    _constr = item_constructor(_type)
    if not _constr?
      log.warn({type: printf("%02X", _type), start: start, length: _length}, "PDU item not implemented")
      return {type: _type, name: 'unknown', _start: start, _end: start + 4 + _length}
    else
      _item = new _constr(@_buff, start, start + 4 + _length)
      log.trace(_item.log_summary(), "decoded item") if log.trace()
      return _item

  log_summary: () ->
    _summary = {}
    for k,v of this
      if k != '_buff'
        if v?.log_summary?
          v = v.log_summary()
        _summary[k] = v
    return _summary

  to_json: () ->
    if @value?
      return @value
    _json = if @_json_name then {name: @name} else {}
    _item_value = (item) ->
      if item?.to_json?
        item = item.to_json()
      return item
    for _k,_v of @var_item_counts
      if _v == 1
        _item = this[_k]
        _json[_k] = _item_value(_item)
      else if this[_k]?
        _json[_k] = for _item in this[_k]
          _item_value(_item)
    return _json

class PDUAssociateRq extends PDU
  type: 0x01
  name: 'association_rq'
  var_item_counts:
    application_context: 1
    presentation_context: -1
    user_information: 1

  decode: () ->
    @_protocol_version = @_buff.readUInt16BE(0)
    @called_aet_title = @_buff.slice(4, 20).toString().trim()
    @calling_aet_title = @_buff.slice(20, 36).toString().trim()
    @decode_var_items(68, @_buff.length)

  to_json: () ->
    _json = super()
    _json.called_aet_title = @called_aet_title
    _json.calling_aet_title = @calling_aet_title
    return _json

class Item extends PDU
  _json_name: false

  constructor: (@_buff, @_start, @_end) ->
    @decode()
    delete @_buff
  ui_str: (offset) ->
    _start = @_start + offset
    return trim_ui(@_buff.toString('binary', _start, @_end))

class ApplicationContextItem extends Item
  type: 0x10
  name: 'application_context'
  decode: () ->
    @value = @ui_str(4)

class PresentationContextItem extends Item
  type: 0x20
  name: 'presentation_context'
  var_item_counts:
    abstract_syntax: 1
    transfer_syntax: -1
  decode: () ->
    @id = @_buff[@_start + 4]
    @decode_var_items(@_start + 8, @_end)
  to_json: () ->
    _json = super()
    _json.id = @id
    return _json

class AbstractSyntaxItem extends Item
  type: 0x30
  name: 'abstract_syntax'
  decode: () ->
    @value = @ui_str(4)

class TransferSyntaxItem extends Item
  type: 0x40
  name: 'transfer_syntax'
  decode: () ->
    @value = @ui_str(4)

class UserInformationItem extends Item
  type: 0x50
  name: 'user_information'
  var_item_counts:
    maximum_length: 1
    asynchronous_operations_window: 1
    implementation_class_uid: 1
    implementation_version_name: 1
    scp_scu_role_selection: -1
  decode: () ->
    @decode_var_items(@_start + 4, @_end)

class MaximumLengthItem extends Item
  type: 0x51
  name: 'maximum_length'
  decode: () ->
    @value = @_buff.readUInt32BE(@_start + 4)

class ImplementationClassUidItem extends Item
  type: 0x52
  name: 'implementation_class_uid'
  decode: () ->
    @value = @ui_str(4)

class AsynchronousOperationsWindowItem extends Item
  type: 0x53
  name: 'asynchronous_operations_window'
  decode: () ->
    @maximum_number_operations_invoked = @_buff.readUInt16BE(@_start + 4)
    @maximum_number_operations_performed = @_buff.readUInt16BE(@_start + 6)
  to_json: () ->
    _json = super()
    _json.maximum_number_operations_invoked = @maximum_number_operations_invoked
    _json.maximum_number_operations_performed = @maximum_number_operations_performed
    return _json

class ScpScuRoleSelectionItem extends Item
  type: 0x54
  name: 'scp_scu_role_selection'
  decode: () ->
    _uid_length = @_buff.readUInt16BE(@_start + 4)
    _start = @_start + 6
    _end = @_start + 6 + _uid_length
    @sop_class_uid = trim_ui(@_buff.toString('binary', _start, _end))
    @scu_role = @_buff[_end]
    @scp_role = @_buff[_end + 1]
  to_json: () ->
    _json = super()
    _json.sop_class_uid = @sop_class_uid
    _json.scu_role = @scu_role
    _json.scp_role = @scp_role
    return _json

class ImplementationVersionNameItem extends Item
  type: 0x55
  name: 'implementation_version_name'
  decode: () ->
    @value = @ui_str(4)

trim_ui = (str) ->
  _len = str.length
  if _len > 0 and str[_len - 1] == '\x00'
    str.slice(0, -1)
  else
    str


PDU_BY_TYPE =
  '01': PDUAssociateRq
pdu_constructor = (type) ->
  _hex = printf("%02X", type)
  return PDU_BY_TYPE[_hex]


ITEM_BY_TYPE =
  '10': ApplicationContextItem
  '20': PresentationContextItem
  '30': AbstractSyntaxItem
  '40': TransferSyntaxItem
  '50': UserInformationItem
  '51': MaximumLengthItem
  '52': ImplementationClassUidItem
  '53': AsynchronousOperationsWindowItem
  '54': ScpScuRoleSelectionItem
  '55': ImplementationVersionNameItem

item_constructor = (type) ->
  _hex = printf("%02X", type)
  return ITEM_BY_TYPE[_hex]

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
