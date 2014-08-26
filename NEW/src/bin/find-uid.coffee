#! /usr/bin/env coffee

# requiring the coffee file is SLOW
try
  uids = require "../lib/uids.js"
catch err
  uids = require "../../lib/uids.js"

for what in process.argv[2...]
  regex = new RegExp(what, "i")
  uids.find(regex)

