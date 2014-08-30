#! /usr/bin/env coffee
#
#

log = require("./logger")("vrs")

UNDEFINED_LENGTH = 0xFFFFFFFF

class DicomError extends Error

class UnexpectedEofOfFile extends DicomError

exports.UNDEFINED_LENGTH = UNDEFINED_LENGTH
exports.DicomError = DicomError
exports.UnexpectedEofOfFile = UnexpectedEofOfFile

##
# little/big endian helpers
#
# only 2 instances will ever be used:
# LITTLE_ENDIAN, BIG_ENDIAN
##
class LittleEndian
  constructor: () ->
    @endianess = "LittleEndian" # for ease of debugging
    # without @endianess, you just see {} when dumping
    # the endianess object
  unpack_uint16: (buff) ->
    buff.readUInt16LE(0)
  unpack_uint16s: (buff, num) ->
    for i in [0...num]
      offset = 2*i
      buff.readUInt16LE(offset)
  unpack_int16s: (buff, num) ->
    for i in [0...num]
      offset = 2*i
      buff.readInt16LE(offset)
  unpack_uint32: (buff) ->
    buff.readUInt32LE(0)
  unpack_uint32s: (buff, num) ->
    for i in [0...num]
      offset = 4*i
      buff.readUInt32LE(offset)
  unpack_int32s: (buff, num) ->
    for i in [0...num]
      offset = 4*i
      buff.readInt32LE(offset)
  unpack_floats: (buff, num) ->
    for i in [0...num]
      offset = 4*i
      buff.readFloatLE(offset)
  unpack_doubles: (buff, num) ->
    for i in [0...num]
      offset = 8*i
      buff.readDoubleLE(offset)

  pack_uint16s: (values) ->
    buff = new Buffer(values.length * 2)
    for idx in [0...values.length]
      offset = 2 * idx
      buff.writeUInt16LE(values[idx], offset)
    buff
  pack_uint32s: (values) ->
    buff = new Buffer(values.length * 4)
    for idx in [0...values.length]
      offset = 4 * idx
      buff.writeUInt32LE(values[idx], offset)
    buff
  pack_int16s: (values) ->
    buff = new Buffer(values.length * 2)
    for idx in [0...values.length]
      offset = 2 * idx
      buff.writeInt16LE(values[idx], offset)
    buff
  pack_int32s: (values) ->
    buff = new Buffer(values.length * 4)
    for idx in [0...values.length]
      offset = 4 * idx
      buff.writeInt32LE(values[idx], offset)
    buff
  pack_floats: (values) ->
    buff = new Buffer(values.length * 4)
    for idx in [0...values.length]
      offset = 4 * idx
      buff.writeFloatLE(values[idx], offset)
    buff
  pack_doubles: (values) ->
    buff = new Buffer(values.length * 8)
    for idx in [0...values.length]
      offset = 8 * idx
      buff.writeDoubleLE(values[idx], offset)
    buff

class BigEndian
  constructor: () ->
    @endianess = "BigEndian" # for ease of debugging
  unpack_uint16: (buff) ->
    buff.readUInt16BE(0)
  unpack_uint16s: (buff, num) ->
    for i in [0...num]
      offset = 2*i
      buff.readUInt16BE(offset)
  unpack_int16s: (buff, num) ->
    for i in [0...num]
      offset = 2*i
      buff.readInt16BE(offset)
  unpack_uint32: (buff) ->
    buff.readUInt32BE(0)
  unpack_uint32s: (buff, num) ->
    for i in [0...num]
      offset = 4*i
      buff.readUInt32BE(offset)
  unpack_int32s: (buff, num) ->
    for i in [0...num]
      offset = 4*i
      buff.readInt32BE(offset)
  unpack_floats: (buff, num) ->
    for i in [0...num]
      offset = 4*i
      buff.readFloatBE(offset)
  unpack_doubles: (buff, num) ->
    for i in [0...num]
      offset = 8*i
      buff.readDoubleBE(offset)

  pack_uint16s: (values) ->
    buff = new Buffer(values.length * 2)
    for idx in [0...values.length]
      offset = 2 * idx
      buff.writeUInt16BE(values[idx], offset)
    buff
  pack_uint32s: (values) ->
    buff = new Buffer(values.length * 4)
    for idx in [0...values.length]
      offset = 4 * idx
      buff.writeUInt32BE(values[idx], offset)
    buff
  pack_int16s: (values) ->
    buff = new Buffer(values.length * 2)
    for idx in [0...values.length]
      offset = 2 * idx
      buff.writeInt16BE(values[idx], offset)
    buff
  pack_int32s: (values) ->
    buff = new Buffer(values.length * 4)
    for idx in [0...values.length]
      offset = 4 * idx
      buff.writeInt32BE(values[idx], offset)
    buff
  pack_floats: (values) ->
    buff = new Buffer(values.length * 4)
    for idx in [0...values.length]
      offset = 4 * idx
      buff.writeFloatBE(values[idx], offset)
    buff
  pack_doubles: (values) ->
    buff = new Buffer(values.length * 8)
    for idx in [0...values.length]
      offset = 8 * idx
      buff.writeDoubleBE(values[idx], offset)
    buff

LITTLE_ENDIAN = new LittleEndian()
BIG_ENDIAN = new BigEndian()

##
#
# Context for coding/decoding.
#
# This keeps track of parameters needed for parsing.
# After creation, the context can not be changed.
# (for the javascript implementation - just leave it alone,
# will you).
# A new context can be created from an old one,
# with some fields changed.
#
##
class Context
  ##
  # Attributes of ctx are copied but overruled by the arguments, if present
  # * endianess: LITTLE_ENDIAN or BIG_ENDIAN
  # * charset: "binary" (=latin1), "utf-8", not the 0008,0005 values
  # * explicit: explicit or implicit ts in effect
  # * encapsulated: inside encapsulated OB
  ##
  constructor: (ctx, obj) ->
    @endianess = obj.endianess ? ctx?.endianess ? LITTLE_ENDIAN
    @charset = obj.charset ? ctx?.charset ? "binary"
    @explicit = obj.explicit ? ctx?.explicit ? true
    @encapsulated = obj.encapsulated ? ctx?.encapsulated ? false

##
# Stack of Dicom Contexts.
#
# They keep track of end positions for nested data elements,
# and actions to perform once that position is reached.
#
# Note that the actions will only be performed when
# the context is autopopped, not when and Sequence/Item
# Delimitation item ends the context.
#
# This is because the end-action is used to emit
# end-events, even without the end item from the dicom stream.
##
class CSObj # an entry in the context stack
  constructor: (@context, @end_position, @action) ->

class ContextStack
  constructor: () ->
    @_stack = []

  ##
  # push a new dicom context with optional end_position and action
  #
  ##
  push: (obj, end_position, action) ->
    context = new Context(@top() ? {}, obj)
    csobj = new CSObj(context, end_position, action)
    log.trace("pushing context: #{csobj}") if log.trace()
    rc = @_stack.push csobj
    log.trace({context: @log_summary()}, "pushed context, this is current now!") if log.trace()

  ##
  # replace the current dicom context
  #
  # only allowed at stack_depth = 1
  #
  ##
  replace: (obj) ->
    if @_stack.length > 1
      throw new DicomError("ContextStack:replace not allowed unless stack depth = 1: #{@stack.length}")
    context = new Context(@top(), obj)
    @_stack[0].context = context
    log.trace({context: @log_summary()}, "replaced root context") if log.trace()

  pop: () ->
    csobj = @_stack.pop()
    log.trace({context: @log_summary()}, "popped context stack, this is current now!") if log.trace()
    csobj.context

  handle_autopops: (pos) ->
    top = @_stack[@_stack.length - 1]
    if top.end_position?
      if pos < top.end_position
        log.trace("handle_autopops: pos #{pos}, not reached end pos #{top.end_position}") if log.trace()
      else
        log.trace("handle_autopops: pos #{pos}, reached end pos #{top.end_position}") if log.trace()
        top.action()
        @_stack.pop()
        return @handle_autopops(pos)
    else
      log.trace("handle_autopops: stream position #{pos}, but no context with autopop on top") if log.trace()
    this

  top: () ->
    @_stack[@_stack.length - 1]?.context

  stack_depth: () ->
    @_stack.length

  log_summary: () ->
    context = @top()
    summary =
      endianess: context.endianess
      charset: context.charset
      explicit: context.explicit
      encapsulated: context.encapsulated
      stack_depth: @_stack.length



##
# 
# DicomEvent for emittings
#
##
class DicomEvent
  constructor: (@element, @vr, @raw, @command) ->
  log_summary: () ->
    summary = {}
    if @element
      summary.element = @element.log_summary?()
    if @vr
      summary.vr = @vr.log_summary?()
    if @raw
      summary.raw = @raw.length
    if @command
      summary.command = @command
    return summary

dicom_raw = (buffer) ->
  return new DicomEvent(null, null, buffer)

dicom_command = (tag, cmd) ->
  return new DicomEvent(tag, null, null, cmd)

exports.DicomEvent = DicomEvent
exports.dicom_raw = dicom_raw
exports.dicom_command = dicom_command

##
# VR base class.
#
# VR objects store bytes received from some file or network stream
# and the context needed to interpret said bytes.
##
class VR
  is_endian: false

  explicit_value_length_bytes: 2
  implicit_value_length_bytes: 4

  # Initialize the VR. Either a buffer or parsed values must be given
  constructor: (context, buffer, values) ->
    @context = context
    if values? and not buffer?
      @encode values
    else
      @buffer = buffer
  # get the first value
  value: () ->
    @values()[0]

  # consume value length from a readbuffer, return value length
  consume_value_length: (readbuffer) ->
    vlb = if @context.explicit
      @explicit_value_length_bytes
    else
      @implicit_value_length_bytes
    switch vlb
      when 2 then length_element = new US(@context)
      when 4 then length_element = new UL(@context)
      when 6
        # skip 2 bytes
        readbuffer.consume 2
        length_element = new UL(@context)
      else
        raise new DicomError("invalue value length bytes (not 2,4 or 6): " + vlb)
    value_length = length_element.consume_value(readbuffer)
    return value_length

  # consume value length and then the values
  consume: (readbuffer) ->
    value_length = @consume_value_length(readbuffer)
    @buffer = readbuffer.consume(value_length)

  # consume and emit - allows us to override in subclasses
  consume_and_emit: (element, readbuffer, decoder, start_position) ->
    value_length = @consume_value_length(readbuffer)
    @_consume_and_emit_known_value_length element, readbuffer, decoder, start_position, value_length

  _consume_and_emit_known_value_length: (element, readbuffer, decoder, start_position, value_length) ->
    if value_length == UNDEFINED_LENGTH
      throw new DicomError("VR::consume_and_emit is not prepared to handle UNDEFINED_LENGTH")
    if value_length < (decoder.streaming_value_length_minimum ? 256)
      @buffer = readbuffer.consume(value_length)
      obj = new DicomEvent(element, this, null, "element")
      decoder.log_and_push obj
    else
      @stream_element(element, readbuffer, decoder, value_length)
  
  # stream the element out (well, the byte buffers anyway)
  stream_element: (element, readbuffer, decoder, value_length) ->
    obj = new DicomEvent(element, this, null, "start_element")
    decoder.log_and_push obj
    obj = new DicomEvent(element, this, null, "end_element")
    decoder._stream_bytes(value_length, obj)

  # log summary for bunyan
  log_summary: () ->
    summary =
      if @buffer?.length < 64
        values: @values()
      else
        length: @buffer?.length

# VR of fixed length
# defaults to 4 bytes length per element.
# these are usually endian.
class FixedLength extends VR
  is_endian: true
  single_value_length: 4

  # consume a single value from the readbuffer
  consume_value: (rb) ->
    @buffer = rb.consume(@single_value_length)
    return @value()

  _vm: (buffer) ->
    buffer.length / @single_value_length

##
#
# Dicom AT (=dAta element Tag).
# 
# encoded as 2 consecutive 16 bit unsigneds giving the group/element of
# a dicom tag.  The value is represented as a single tag number.
##
class AT extends FixedLength
  values: () ->
    g_e = @context.endianess.unpack_uint16s(@buffer, @_vm(@buffer) * 2)
    for idx in [0...g_e.length] by 2
      (g_e[idx]<<16) ^ g_e[idx + 1]
  encode: (values) ->
    g_e = []
    for v in values
      g = v >> 16
      e = v & 0xFFFF
      g_e.push g
      g_e.push e
    @buffer = @context.endianess.pack_uint16s(g_e)

##
#
# Dicom FD (=Float Double) 64bit floats
#
##
class FD extends FixedLength
  single_value_length: 8
  values: () ->
    @context.endianess.unpack_doubles(@buffer, @_vm(@buffer))
  encode: (values) ->
    @buffer = @context.endianess.pack_doubles(values)


##
#
# Dicom FL (=Float) IEEE 32bit floats
#
##
class FL extends FixedLength
  values: () ->
    @context.endianess.unpack_floats(@buffer, @_vm(@buffer))
  encode: (values) ->
    @buffer = @context.endianess.pack_floats(values)


##
#
# Dicom SL (=Signed Long) 32-bit signed integers
#
##
class SL extends FixedLength
  values: () ->
    @context.endianess.unpack_int32s(@buffer, @_vm(@buffer))
  encode: (values) ->
    @buffer = @context.endianess.pack_int32s(values)


##
#
# Dicom SS (=Signed Short) 16-bit signed integers
#
##
class SS extends FixedLength
  single_value_length: 2
  values: () ->
    @context.endianess.unpack_int16s(@buffer, @_vm(@buffer))
  encode: (values) ->
    @buffer = @context.endianess.pack_int16s(values)


##
#
# Dicom UL (=Unsigned Long) 32-bit unsigned integers
#
##
class UL extends FixedLength
  values: () ->
    @context.endianess.unpack_uint32s(@buffer, @_vm(@buffer))
  encode: (values) ->
    @buffer = @context.endianess.pack_uint32s(values)


##
#
# Dicom US (=Unsigned Short) 16-bit unsigned integers
#
##
class US extends FixedLength
  single_value_length: 2
  values: () ->
    @context.endianess.unpack_uint16s(@buffer, @_vm(@buffer))
  encode: (values) ->
    @buffer = @context.endianess.pack_uint16s(values)

# base class for the 'other' VRs ... OB, OW, OF, UN
class OtherVR extends FixedLength
  explicit_value_length_bytes: 6
  values: () ->
    [@buffer.toString('base64')]


##
# 
# Dicom OB (= Other Byte)
#
##
class OB extends OtherVR
  # consume and emit - handle encapsulated pixeldata
  consume_and_emit: (element, readbuffer, decoder, start_position) ->
    value_length = @consume_value_length(readbuffer)
    if value_length != UNDEFINED_LENGTH
      return @_consume_and_emit_known_value_length(element, readbuffer, decoder, start_position, value_length)
    # push encaps context
    context = decoder.context
    context.push {encapsulated: true}
    obj = new DicomEvent(element, this, undefined, "start_element")
    decoder.log_and_push obj

##
#
# Dicom UN (= UNknown)
#
##
class UN extends OtherVR
  # UN may be of undefined length if it is really a private sequence tag
  consume_and_emit: (element, readbuffer, decoder, start_position) ->
    value_length = @consume_value_length(readbuffer)
    log.debug({length: value_length}, "UN consume and emit") if log.debug()
    if value_length != UNDEFINED_LENGTH
      # just stream it out, like all other OtherVRs
      return @_consume_and_emit_known_value_length(element, readbuffer, decoder, start_position, value_length)
    end_cb = () ->
      _obj = new DicomEvent(element, this, null, "end_sequence")
      decoder.log_and_push _obj
    decoder.context.push({explicit: false}, null, end_cb)

    obj = new DicomEvent(element, this, null, "start_sequence")
    decoder.log_and_push obj

##
#
# Dicom OW (= Other Word)
#
##
class OW extends OtherVR

##
#
# DICOM OF (= Other Float)
#
##
class OF extends OtherVR


##
#
# Dicom SQ (= SeQuence) VR
#
# this does not consume its values - they should be parsed
# instead we push a new context, maybe with autopop
# and let the driving loop do its work
#
##
class SQ extends VR
  explicit_value_length_bytes:6

  values: () ->
    undefined

  consume_and_emit: (element, readbuffer, decoder, start_position) ->
    value_length = @consume_value_length(readbuffer)
    log.debug({length: value_length}, "SQ consume and emit") if log.debug()
    end_position = undefined
    if value_length != UNDEFINED_LENGTH
      end_position = start_position + value_length
    end_cb = () ->
      _obj = new DicomEvent(element, this, null, "end_sequence")
      decoder.log_and_push _obj
    decoder.context.push({}, end_position, end_cb)
    obj = new DicomEvent(element, this, null, "start_sequence")
    decoder.log_and_push obj


_ends_with = (str, char) ->
  len = str.length
  len > 0 and str[len-1] == char

# String VR base class
class Stringish extends VR
  allow_multiple_values: true
  padding_character: ' '
  split_str: '\\'

  values: () ->
    s = @buffer.toString(@context.charset)
    if _ends_with s, @padding_character
      s = s.slice(0, -1)
    if @allow_multiple_values
      return s.split(@split_str)
    return [s]

  encode: (values) ->
    s = values.join(@split_str) + @padding_character
    b = new Buffer(s, @context.charset)
    if b.length % 2
      b = b.slice(0, -1)
    @buffer = b

##
#
# Dicom AE (= Application Entity).
#
# 16 characters max, space padded.
##
class AE extends Stringish

##
#
# Dicom AS (= Age String).
#
# 4 bytes fixed, of the form nnnD, nnnW, nnnM or nnnY.
# E.g. 003W would mean 3 weeks old.
#
##
class AS extends Stringish

##
#
# Dicom CS (= Code String).
#
# 16 bytes max, only uppercase letters, 0-9, space and underscore
# allowed. Leading an trailing spaces are non-significant.
##
class CS extends Stringish

##
#
# Dicom DA (= DAte).
#
# A string of the form YYYYMMDD
#
# When range matching, -YYYYMMDD, YYYYMMDD- and YYYYMMDD-YYYYMMDD
# are also possible.
##
class DA extends Stringish

##
#
# Dicom DS (= Decimal String).
#
# A fixed or floating point number represented as a String.
#
# Note: we leave this as a String.
#
##
class DS extends Stringish

##
#
# Dicom DT (= Date and Time).
#
# A concatenated date-tiome character string in the format:
# YYYYMMDDHHMMSS.FFFFFF&ZZXX
##
class DT extends Stringish

##
#
# Dicom IS (= Integer String)
#
##
class IS extends Stringish

##
#
# Dicom LO (= LOng string).
#
# Despite being LOng, 64 characters maximum, spaced padded, no backspace.
# => Multiple values are possible
##
class LO extends Stringish

##
#
# Dicom LT (= Long Text).
#
# This can not be multivalued, so it can contain backslashes.
##
class LT extends Stringish
  allow_multiple_values: false

##
#
# Dicom PN (= Person Name).
#
# TODO: handling of component groups.
#
# Limited to 64 characters per component group (not enforced)
##
class PN extends Stringish

##
#
# Dicom SH (= Short String).
#
# 16 bytes max, no backslash ==> multiple values.
#
##
class SH extends Stringish

##
#
# Dicom ST (= Short Text).
#
# 1024 characters maximum, no multiple values ===> backslash is allowed in text.
##
class ST extends Stringish
  allow_multiple_values: false

##
#
# Dicom TM (= TiMe).
#
# HHMMSS.FFFFFF
##
class TM extends Stringish

##
#
# Dicom UI (= UId string).
#
# Max 64 characters, padded with zero-byte, only valid uids allowed.
# I.e. only 0-9 and . allowed, must start and end with digit,
# no consecutive dots, no 0 prefixes in internal digit runs,
# .0. is not allowed.
##
class UI extends Stringish
  padding_character: "\x00"

##
#
# Dicom UT (= Unlimited Text).
#
# Size only limited by length field.  No multiple values allowed,
# so literal backslashes are OK.
##
class UT extends Stringish
  allow_multiple_values: false
  explicit_value_length_bytes: 6


_VR_DICT = {
  # fixed length vrs
  'AT': AT,
  'FD': FD,
  'FL': FL,
  'SL': SL,
  'SS': SS,
  'UL': UL,
  'US': US,

  # other vrs
  'OB': OB,
  'UN': UN,
  'OW': OW,
  'OF': OF,

  # sequence
  'SQ': SQ,

  # string vrs
  'AE': AE,
  'AS': AS,
  'CS': CS,
  'DA': DA,
  'DS': DS,
  'DT': DT,
  'IS': IS,
  'LO': LO,
  'LT': LT,
  'PN': PN,
  'SH': SH,
  'ST': ST,
  'TM': TM,
  'UI': UI,
  'UT': UT,
}

for_name = (name, ctx, buffer, values) ->
  constr_fn = _VR_DICT[name]
  if not constr_fn?
    throw new DicomError("Unknown VR: #{name}")
  return new constr_fn(ctx, buffer, values)

exports.LITTLE_ENDIAN = LITTLE_ENDIAN
exports.BIG_ENDIAN = BIG_ENDIAN
exports.Context = Context
exports.ContextStack = ContextStack
exports.AT = AT
exports.FD = FD
exports.FL = FL
exports.SL = SL
exports.SS = SS
exports.UL = UL
exports.US = US

exports.OB = OB
exports.OW = OW
exports.OF = OF
exports.UN = UN
exports.SQ = SQ

exports.AE = AE
exports.AS = AS
exports.CS = CS
exports.DA = DA
exports.DS = DS
exports.DT = DT
exports.IS = IS
exports.LO = LO
exports.LT = LT
exports.PN = PN
exports.SH = SH
exports.ST = ST
exports.TM = TM
exports.UI = UI
exports.UT = UT

exports.for_name = for_name
exports._VR_DICT = _VR_DICT
