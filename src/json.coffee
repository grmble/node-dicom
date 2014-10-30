#! /usr/bin/env coffee

##
#
# DICOM Json Model
#
# http://medical.nema.org/dicom/2013/output/chtml/part18/sect_F.2.html
#
##

fs = require("fs")
stream = require("stream")
zlib = require("zlib")

printf = require("printf")
ConcatStream = require("concat-stream")
minimist = require("minimist")

tags = require("../lib/tags")
decoder = require("../lib/decoder")
log = require("./logger")("json")

JsonEncoder = require("./json/encoder")
JsonSink = require("./json/sink")
JsonSource = require("./json/source")


# remain compatible with old, all-in-one json.coffee
_COMPATIBILITY = true
if _COMPATIBILITY
  exports.JsonEncoder = JsonEncoder
  exports.JsonSink = JsonSink
  exports.JsonSource = JsonSource

# helper functions
# path elements may be anything that can be
# tags.for_tag-ed except NUBMERS - they
# represent sequence item access
get_element = (json, path...) ->
  lookup = []
  must_pop = false
  for p in path
    if (typeof p) == 'number'
      lookup.push p
      must_pop = false
    else
      lookup.push tags.for_tag(p).tag_str
      lookup.push "Value"
      must_pop = true
  if must_pop
    lookup.pop()
  result = json
  for x in lookup
    result = result?[x]
  return result

get_values = (json, path...) ->
  return get_element(json, path...)?.Value

get_value = (json, path...) ->
  return get_values(json, path...)?[0]

get_vr = (json, path...) ->
  return get_element(json, path...)?.vr

_get_filename = (obj_or_fn) ->
  if typeof(obj_or_fn) == 'string'
    obj_or_fn
  else
    obj_or_fn.filename

_get_bulkdata_uri = (obj_or_fn) ->
  if typeof(obj_or_fn) == 'string'
    obj_or_fn
  else
    obj_or_fn.bulkdata_uri ? obj_or_fn.filename

file2jsonstream = (fn, cb) ->
  fs.createReadStream _get_filename(fn)
  .on 'error', cb
  .pipe decoder {guess_header: true}
  .on 'error', cb
  .pipe new JsonEncoder({bulkdata_uri: _get_bulkdata_uri(fn)})
  .on 'error', cb

file2json = (fn, cb) ->
  file2jsonstream(fn, cb)
  .pipe new JsonSink(cb)
  .on 'error', cb

# cb is called for errors
gunzip2jsonstream = (fn, cb) ->
  fs.createReadStream _get_filename(fn)
  .on 'error', cb
  .pipe zlib.createGunzip()
  .on 'error', cb
  .pipe decoder {guess_header: true}
  .on 'error', cb
  .pipe new JsonEncoder({bulkdata_uri: _get_bulkdata_uri(fn)})
  .on 'error', cb

gunzip2json = (fn, cb) ->
  gunzip2jsonstream(fn, cb)
  .pipe new JsonSink(cb)
  .on 'error', cb


# make a decoder piping into json sink
# errors are correctly chained,
# returns the DECODER
# options: transfer_syntax (for decoder), bulkdata_uri for encoder
decoder2json = (opts, cb) ->
  _dec = new decoder(opts)
  _dec.on 'error', cb
  .pipe new JsonEncoder(opts)
  .on 'error', cb
  .pipe new JsonSink(cb)
  .on 'error', cb
  return _dec

exports.get_element = get_element
exports.get_values = get_values
exports.get_value = get_value
exports.get_vr = get_vr
exports.file2jsonstream = file2jsonstream
exports.gunzip2jsonstream = gunzip2jsonstream
exports.file2json = file2json
exports.gunzip2json = gunzip2json
exports.decoder2json = decoder2json


_err_cb = (err) ->
  console.error "Error:", err.stack
  process.exit 1

if require.main is module
  options = minimist(process.argv.slice(2),
            {boolean: ['gunzip', 'emit'], alias: {z: 'gunzip', 'e': 'emit'}})
  filename = options._[0]
  if options.gunzip
    input = gunzip2jsonstream(filename, _err_cb)
  else
    input = file2jsonstream(filename, _err_cb)

  if options.emit
    sink = new JsonSink (err, data) ->
      throw err if err
      log.info "setting up json source"
      source = new JsonSource(data)
      source.pipe process.stdout
    input.pipe sink
  else
    input.pipe process.stdout

