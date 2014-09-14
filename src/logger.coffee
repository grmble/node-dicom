#! /usr/bin/env coffee
#

##
#
# configurable logging
#
#
##

bunyan = require "bunyan"

##
#
# Prefix for ENV var based configuration
#
##
ENV_PREFIX = "NDCM"
DEFAULTS =
  'level': 'info'
STREAM_DICT =
  'process.stdout': process.stdout,
  'process.stderr': process.stderr

_env = (what, name) ->
  _what = what.toUpperCase()
  _name = name.toUpperCase()
  return (process.env["#{ENV_PREFIX}_#{_what}_#{_name}"] ?
    process.env["#{ENV_PREFIX}_#{_what}"] ?
    DEFAULTS[_what])

logger = (names...) ->
  name = names.join("_")
  obj =
    'name': name,
    'level': _env('level', name)
  stream = _env('stream', name)
  if stream and STREAM_DICT[stream]
    obj.stream = STREAM_DICT[stream]
  path = _env('path', name)
  if path
    obj.path = path
  if not path? and not stream?
    obj.stream = process.stderr
  return bunyan.createLogger(obj)

module.exports = logger
