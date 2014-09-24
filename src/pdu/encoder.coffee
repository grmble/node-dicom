#! /usr/bin/env coffee

util = require("util")
stream = require("stream")
printf = require("printf")
vrs = require("../../lib/vrs")

log = require("../logger")('pdu', 'encoder')


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
      buff = @__encode_pdu(pdu)
      log.trace({length: buff.length}, "_transform: emitting pdu buffer")
      @push buff
      cb()
    catch err
      log.error({error: err}, "_transform: error")
      cb(err)

  __encode_pdu: (pdu) ->
    switch pdu.pdu_type
      when 0x01 then @__encode_assoc_rq_pdu(pdu)
      else
        throw new vrs.DicomError(printf("Unknown pdu type: %02X", pdu.pdu_type))

  __encode_assoc_rq_pdu: (pdu) ->
    __app_ctx = @__encode_application_context_item(pdu.application_context)
    __pres_ctx = @__encode_presentation_context_items(pdu.presentation_context)
    __var_len = __app_ctx.length + __pres_ctx.length
    # __user_inf = @__encode_user_information_item(pdu.user_information)
    __header = Buffer.concat([new Buffer([0x01, 0x00]), mk_uint32(66 + __var_len),
      # protocol version
      mk_uint16(1),
      # called & calling aet title
      new Buffer(printf("%-16s%-16s", pdu.called_aet_title.substr(0,16), pdu.calling_aet_title.substr(0,16)), 'binary'),
      # 32 reserved bytes
      ZERO_BUFF.slice(0, 32) ])

    return Buffer.concat([__header, __app_ctx, __pres_ctx])

  __encode_application_context_item: (app_ctx) ->
    _ctx = app_ctx.application_context_name
    return Buffer.concat([new Buffer([0x10, 0]), mk_uint16(_ctx.length), new Buffer(_ctx, 'binary')])

  __encode_presentation_context_items: (pres_ctx) ->
    __buffers = for __ctx in pres_ctx
      __id = new Buffer([__ctx.presentation_context_id, 0, 0, 0])
      __as = @__encode_abstract_syntax_item(__ctx.abstract_syntax)
      __ts = @__encode_transfer_syntax_items(__ctx.transfer_syntax)
      __len = __id.length + __as.length + __ts.length
      Buffer.concat([new Buffer([0x20, 0]), mk_uint16(__len), __id, __as, __ts])
    Buffer.concat(__buffers)

  __encode_abstract_syntax_item: (as) ->
    __str = as.abstract_syntax_name
    return Buffer.concat([new Buffer([0x30, 0]), mk_uint16(__str.length), new Buffer(__str, 'binary')])

  __encode_transfer_syntax_items: (items) ->
    __buffers = for __ts in items
      __name = __ts.transfer_syntax_name
      if util.isArray(__name)
        __name = __name.join('\\')
      __len = __name.length
      Buffer.concat([new Buffer([0x40, 0]), mk_uint16(__len), new Buffer(__name, 'binary')])
    Buffer.concat(__buffers)

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

if require.main is module
  _echo = {
    "pdu_type": 1,
    "protocol_version": 1,
    "called_aet_title": "TESTME",
    "calling_aet_title": "DCMECHO",
    "application_context": {
      "item_type": 16,
      "application_context_name": "1.2.840.10008.3.1.1.1"
    },
    "presentation_context": [
      {
        "item_type": 32,
        "presentation_context_id": 1,
        "abstract_syntax": {
          "item_type": 48,
          "abstract_syntax_name": "1.2.840.10008.1.1"
        },
        "transfer_syntax": [
          {
            "item_type": 64,
            "transfer_syntax_name": "1.2.840.10008.1.2"
          }
        ]
      }
    ],
    "user_information": {
      "item_type": 80,
      "maximum_length": {
        "item_type": 81,
        "maximum_length_received": 16384
      },
      "implementation_class_uid": [
        {
          "item_type": 82,
          "implementation_class_uid": "1.2.40.0.13.1.1"
        }
      ],
      "asynchronous_operations_window": [
        {
          "item_type": 83,
          "maximum_number_operations_invoked": 0,
          "maximum_number_operations_performed": 0
        }
      ],
      "implementation_version_name": [
        {
          "item_type": 85,
          "implementation_version_name": "dcm4che-2.0"
        }
      ]
    }
  }
  _enc = new PDUEncoder()
  _enc.on 'data', (buff) ->
    console.log "BUFFER:", buff
  _enc.write _echo
