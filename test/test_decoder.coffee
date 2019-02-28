#! /usr/bin/env /coffee
#
# test the decoder for particular edge cases
fs = require "fs"
zlib = require "zlib"

decoder = require "../lib/decoder"

# in SCSARAB 0002,0001 starts at offset 0xf4
# The first non-metadata element starts at 0x14c, ends at 0x15e

exports.DecoderTest =
  "test first chuck does not contain TransferSyntaxUID": (test) ->
    test.expect 1

    failure_detected = false

    file = fs.createReadStream "test/charsettests/SCSARAB.gz"
    gunzip = zlib.createGunzip()
    file.pipe gunzip

    decoder = decoder { read_header: true }
    decoder.on 'data', (data) =>
      # console.log data
      return

    decoder.once 'error', (err) =>
      #console.log 'decoder error'
      failure_detected = true
      test.ok false, 'Decoder should not throw an error.'
      test.done()
      gunzip.end()
      file.destroy()

    decoder.on 'end', () =>
      console.log 'decoder end'
      test.ok true
      test.done()

    first_chunk_handled = false
    gunzip.on 'readable', (foo) =>
      if failure_detected
        return

      if not first_chunk_handled
        first_chunk = gunzip.read 0xf4
        if first_chunk
          decoder.write first_chunk
          first_chunk_handled = true

      while (chunk = gunzip.read())
        decoder.write chunk

    gunzip.on 'end', () =>
      console.log 'gunzip ended'
      decoder.end()


