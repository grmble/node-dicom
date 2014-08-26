#! /usr/bin/env coffee

# requiring the coffee file is SLOW
try
  tags = require "../lib/tags.js"
catch err
  tags = require "../../lib/tags.js"

for what in process.argv[2...]
  regex = new RegExp(what, "i")
  tags.find(regex)

