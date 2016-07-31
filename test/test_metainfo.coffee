#! /usr/bin/env coffee
#
# test parsing metainfo with dodgy metainfo group length
#

fs = require "fs"
zlib = require "zlib"

tags = require "../lib/tags"
decoder = require "../lib/decoder"
json = require "../lib/json"

exports.MetainfoTest =
  "test decoding file": (test) ->
    test.expect 3
    json.gunzip2json "test/metainfo_tests/dodgy_metainfo_length.dcm.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      # test that file could be read - it used to fail before tags.ImplementationVersionName
      test.equal "E120", json.get_value(data, tags.ImplementationVersionName)
      test.equal "ALL_AbdomenSAFIRE", json.get_value(data, tags.ProtocolName)

      # test patient ids sequence has length one with one empty object
      id_seq = json.get_values(data, tags.OtherPatientIDsSequence)
      test.deepEqual [{}], id_seq

      test.done()
