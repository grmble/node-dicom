#! /usr/bin/env coffee

stream = require("stream")
printf = require("printf")
readbuffer = require("./readbuffer")
vrs = require("../lib/vrs")

log = require("./logger")('pdu')

# helper: total length for array of buffers
total_length = (arr) ->
  arr.reduce((sum, buff) ->
    return sum + buff.length
  , 0)

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
  _single_value: false

  constructor: (buff_or_json) ->
    if buff_or_json instanceof Buffer
      @_buff = buff_or_json
      @decode()
      delete @_buff
    else
      @from_json buff_or_json
    return this

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

  from_json: (json) ->
    if @_single_value
      @value = json
      return
    for _k, _v of @var_item_counts
      _constr = ITEM_BY_NAME[_k]
      if not _constr?
        throw new vrs.DicomError "no such item: #{_k}"
      log.trace {name: _k, count: _v, constr: _constr}, "named item"
      if _v == 1
        this[_k] = new _constr(json[_k])
      else
        if json[_k]
          this[_k] = for _x in json[_k]
            new _constr(_x)
      log.trace {json: json[_k], result: this[_k]}, "from json result"
    return

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

  encode: () ->
    _buffers = ['']
    _buffers.push @application_context.encode()
    for item in @presentation_context
      _buffers.push item.encode()
    _buffers.push @user_information.encode()
    # _buffers.push @user_information.encode()
    _var_len = total_length(_buffers)
    _header = Buffer.concat([new Buffer([0x01, 0x00]), mk_uint32(68 + _var_len),
                              # protocol version
                              mk_uint16(1),
                              # reserved
                              new Buffer([0x00, 0x00]),
                              # called & calling aet title
                              new Buffer(printf("%-16s%-16s", @called_aet_title.substr(0,16),
                                @calling_aet_title.substr(0,16)), 'binary'),
                              # 32 reserved bytes
                              ZERO_BUFF.slice(0, 32) ])
    _buffers[0] = _header
    return Buffer.concat(_buffers)

  to_json: () ->
    _json = super()
    _json.called_aet_title = @called_aet_title
    _json.calling_aet_title = @calling_aet_title
    return _json

  from_json: (json) ->
    @called_aet_title = json.called_aet_title
    @calling_aet_title = json.calling_aet_title
    return super(json)

class PDUAssociateAc extends PDUAssociateRq

class Item extends PDU
  _json_name: false

  constructor: (buff_or_json, start, end) ->
    if buff_or_json instanceof Buffer
      @_start = start
      @_end = end
    super(buff_or_json)

  ui_str: (offset) ->
    _start = @_start + offset
    _str = @_buff.toString('binary', _start, @_end)
    _ui = trim_ui(_str)
    # log.trace(start: _start, end: @_end, str: _str, ui:_ui, length: @_buff.length, buff: @_buff.slice(_start, @_end), "ui_str")
    return _ui

  encode_value_str: () ->
    # log.trace(length: @value.length, value: @value, "encode_value_str")
    return Buffer.concat [new Buffer([@type, 0]), mk_uint16(@value.length), new Buffer(@value, 'binary')]

class ApplicationContextItem extends Item
  type: 0x10
  name: 'application_context'
  _single_value: true
  decode: () ->
    @value = @ui_str(4)
  encode: () ->
    return @encode_value_str()

class PresentationContextItem extends Item
  type: 0x20
  name: 'presentation_context'
  var_item_counts:
    abstract_syntax: 1
    transfer_syntax: -1
  decode: () ->
    @id = @_buff[@_start + 4]
    @decode_var_items(@_start + 8, @_end)
  encode: () ->
    _buffers = [
      '',
      @fixed_fields(),
      @abstract_syntax.encode()
      Buffer.concat(_ts.encode() for _ts in @transfer_syntax)
    ]
    _len = total_length(_buffers)
    _header = Buffer.concat([new Buffer([0x20, 0]), mk_uint16(_len)])
    _buffers[0] = _header
    return Buffer.concat(_buffers)

  fixed_fields: () ->
    new Buffer([@id, 0, 0, 0])

  to_json: () ->
    _json = super()
    _json.id = @id
    return _json

  from_json: (json) ->
    @id = json.id
    return super(json)

class PresentationContextItemAc extends PresentationContextItem
  type: 0x21
  name: 'presentation_context_ac'
  decode: () ->
    super()
    @resultReason = @_buff[@_start + 6]
  fixed_fields: () ->
    new Buffer([@id, 0, @resultReason, 0])
  to_json: () ->
    _json = super()
    _json.resultReason = @resultReason
    return _json
  from_json: (json) ->
    @resultReason = json.resultReason
    return super(json)


class AbstractSyntaxItem extends Item
  type: 0x30
  name: 'abstract_syntax'
  _single_value: true
  decode: () ->
    @value = @ui_str(4)
  encode: () ->
    return @encode_value_str()

class TransferSyntaxItem extends Item
  type: 0x40
  name: 'transfer_syntax'
  _single_value: true
  decode: () ->
    @value = @ui_str(4)
  encode: () ->
    return @encode_value_str()

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
  encode: () ->
    _buffers = [
      '',
      @maximum_length.encode()
      @implementation_class_uid.encode()
      @asynchronous_operations_window.encode()
    ]
    if @scp_scu_role_selection
      _buffers.push Buffer.concat(_rs.encode() for _rs in @scp_scu_role_selection)
    _buffers.push @implementation_version_name.encode()
    _len = total_length(_buffers)
    _header = Buffer.concat([new Buffer([@type, 0]), mk_uint16(_len)])
    _buffers[0] = _header
    return Buffer.concat(_buffers)


class MaximumLengthItem extends Item
  type: 0x51
  name: 'maximum_length'
  _single_value: true
  decode: () ->
    @value = @_buff.readUInt32BE(@_start + 4)
  encode: () ->
    _vbuff = new Buffer(4)
    _vbuff.writeUInt32BE(@value, 0)
    return Buffer.concat [new Buffer([@type, 0]), mk_uint16(4), _vbuff]

class ImplementationClassUidItem extends Item
  type: 0x52
  name: 'implementation_class_uid'
  _single_value: true
  decode: () ->
    @value = @ui_str(4)
  encode: () ->
    return @encode_value_str()

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
  from_json: (json) ->
    @maximum_number_operations_invoked = json.maximum_number_operations_invoked
    @maximum_number_operations_performed = json.maximum_number_operations_performed
    return super(json)
  encode: () ->
    _vbuff = new Buffer(4)
    _vbuff.writeUInt16BE(@maximum_number_operations_invoked, 0)
    _vbuff.writeUInt16BE(@maximum_number_operations_performed, 2)
    return Buffer.concat [new Buffer([@type, 0]), mk_uint16(4), _vbuff]


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
  from_json: (json) ->
    @sop_class_uid = json.sop_class_uid
    @scu_role = json.scu_role
    @scp_reole = json.scp_role
    return super(json)
  encode: () ->
    _buffers = [
      '',
      mk_uint16(@sop_class_uid.length)
      new Buffer(@sop_class_uid, 'binary')
      new Buffer([@scu_role, @scp_role])
    ]
    _len = total_length(_buffers)
    _header = Buffer.concat([new Buffer([@type, 0]), mk_uint16(_len)])
    _buffers[0] = _header
    # log.trace(buffers: _buffers, "ScpScuRoleSelection>>encode")
    return Buffer.concat(_buffers)



class ImplementationVersionNameItem extends Item
  type: 0x55
  name: 'implementation_version_name'
  _single_value: true
  decode: () ->
    @value = @ui_str(4)
  encode: () ->
    return @encode_value_str()

trim_ui = (str) ->
  _len = str.length
  if _len > 0 and str[_len - 1] == '\x00'
    str.slice(0, -1)
  else
    str

PDU_BY_TYPE =
  '01': PDUAssociateRq
  '02': PDUAssociateAc

PDU_BY_NAME =
  'association_rq': PDUAssociateRq
  'association_ac': PDUAssociateAc
pdu_constructor = (type) ->
  _hex = printf("%02X", type)
  return PDU_BY_TYPE[_hex]
pdu_by_name = (arg) ->
  if arg instanceof PDU
    return arg
  return new (PDU_BY_NAME[arg.name])(arg)


ITEM_BY_TYPE =
  '10': ApplicationContextItem
  '20': PresentationContextItem
  '21': PresentationContextItemAc
  '30': AbstractSyntaxItem
  '40': TransferSyntaxItem
  '50': UserInformationItem
  '51': MaximumLengthItem
  '52': ImplementationClassUidItem
  '53': AsynchronousOperationsWindowItem
  '54': ScpScuRoleSelectionItem
  '55': ImplementationVersionNameItem

ITEM_BY_NAME =
  'application_context': ApplicationContextItem
  'presentation_context': PresentationContextItem
  'presentation_context_ac': PresentationContextItemAc
  'abstract_syntax': AbstractSyntaxItem
  'transfer_syntax': TransferSyntaxItem
  'user_information': UserInformationItem
  'maximum_length': MaximumLengthItem
  'implementation_class_uid': ImplementationClassUidItem
  'asynchronous_operations_window': AsynchronousOperationsWindowItem
  'scp_scu_role_selection': ScpScuRoleSelectionItem
  'implementation_version_name': ImplementationVersionNameItem

item_constructor = (type) ->
  _hex = printf("%02X", type)
  return ITEM_BY_TYPE[_hex]

ZERO_BUFF = new Buffer(128)

##
# PDUEncoder
#
# Tranform-Stream reading pdu js object
# and emitting pdu buffer
##
class PDUEncoder extends stream.Transform
  constructor: (options)->
    if not (this instanceof PDUEncoder)
      return new PDUEncoder(options)
    super(options)
    @_writableState.objectMode = true
    @_readableState.objectMode = false

  _transform: (pdu, _, cb) ->
    try
      __buff = pdu_by_name(pdu).encode()
      log.trace({length: __buff.length}, "_transform: emitting pdu buffer")
      @push __buff
      cb()
    catch err
      log.error({error: err}, "_transform: error")
      cb(err)

  _flush: () ->
    log.debug("_flush")

mk_uint16 = (num) ->
  _buff = new Buffer(2)
  _buff.writeUInt16BE(num, 0)
  return _buff
mk_uint32 = (num) ->
  _buff = new Buffer(4)
  _buff.writeUInt32BE(num, 0)
  return _buff

exports.PDUDecoder = PDUDecoder
exports.PDUEncoder = PDUEncoder
exports.PDUAssociateRq = PDUAssociateRq



net = require 'net'

echo_scu = (opts, cb) ->
  _aet = opts.aet
  _local = opts.local_aet
  _conn = net.connect opts, () ->
    console.log "connected to", opts
    _enc.write {
      "name": "association_rq",
      "called_aet_title": _aet,
      "calling_aet_title": _local,
      "application_context": "1.2.840.10008.3.1.1.1"
      "presentation_context": [
        "id": 1,
        "abstract_syntax": "1.2.840.10008.1.1",
        "transfer_syntax": ["1.2.840.10008.1.2"]]
      "user_information":
        "maximum_length": 16384
        # "implementation_class_uid": "1.2.40.0.13.1.1" # dcm4chee
        "implementation_class_uid": "1.2.40.0.13.1.1.47"
        "asynchronous_operations_window":
          "maximum_number_operations_invoked": 0
          "maximum_number_operations_performed": 0
        "implementation_version_name": "node-dicom"
    }

  _enc = new PDUEncoder()
  _dec = new PDUDecoder()
  _enc.pipe _conn
  _conn.pipe _dec
  # _conn.on 'data', (data) ->
  #   require('fs').writeFileSync("/tmp/x.x", data)

  _conn.on 'error', cb
  _enc.on 'error', cb
  _dec.on 'error', cb

  _dec.on 'data', (data) ->
    console.log "RECEIVED:", JSON.stringify(data, null, 2)


if require.main is module
  if true
    echo_scu host: "192.168.2.19", port: 11112, aet: "TESTME", local_aet: "XXX", (err, data) ->
      if err
        console.log "ERROR: ", err
        console.log "stack:", err.stack
        process.exit(1)
      console.log "DATA:", data
  if false
    require('fs').createReadStream("/tmp/x.x")
    .pipe new PDUDecoder()