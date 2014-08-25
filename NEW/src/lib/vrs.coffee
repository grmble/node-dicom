#! /usr/bin/env coffee
#
#

_UNDEFINED_LENGTH = 0xFFFFFFFF
_STREAM_BLOCK_SIZE = 16 * 1024

class DicomError extends Error

class UnexpectedEofOfFile extends DicomError

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
  constructor: (ctx, endianess, charset, explicit, encapsulated) ->
    @endianess = endianess ? ctx?.endianess ? LITTLE_ENDIAN
    @charset = charset ? ctx?.charset ? "binary"
    @explicit = explicit ? ctx?.explicit ? true
    @encapsulated = encapsulated ? ctx?.encapsulated ? false

##
# Stack of Dicom Contexts.
#
# They keep track of end positions for nested data elements,
# and actions to perform once that position is reached.
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
  push: (context, end_position, action) ->
    csobj = new CSObj(context, end_position, action)
    @_stack.push csobj

  pop: () ->
    csobj = @_stack.pop
    if csobj.action
      csobj.action()
    csobj.context

  handle_autopops: (pos) ->
    top = @_stack[@_stack.length - 1]
    if top.end_position? and top.endposition <= pos
      dbg "handle_autopops: #{top.end_position} <= #{pos}"
      top.action()
      @_stack.pop()
    this

  top: () ->
    @_stack[@_stack.length - 1]


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

# VR of fixed length
# defaults to 4 bytes length per element.
# these are usually endian.
class FixedLength extends VR
  is_endian: true
  single_value_length: 4

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
  # XXX: endianess changes for OW/OF

  values: () ->
    @buffer

# XXX the other classes need to do some fancy output
# may not be possible to do this here in java/coffeescript
# but look here in the python implementation

##
# 
# Dicom OB (= Other Byte)
#
##
class OB extends OtherVR

##
#
# Dicom UN (= UNknown)
#
##
class UN extends OtherVR

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
##
class SQ extends VR
  explicit_value_length_bytes:6

  values: () ->
    undefined
  # XXX fancy read_and_emit stuff missing

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
  explicit_value_length: 6


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
  konstructor = _VR_DICT[name]
  konstruktor ctx, buffer, values


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
