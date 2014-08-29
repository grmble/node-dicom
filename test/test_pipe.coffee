#! /usr/bin/env coffee
#
# test the dicom decode / json pipeline
fs = require "fs"
tags = require "../lib/tags"
decoder = require "../lib/decoder"
json = require "../lib/json"

file2json = (fn, cb) ->
  fs.createReadStream fn
  .pipe decoder {guess_header: true}
  .pipe new json.JsonEncoder()
  .pipe new json.JsonSink(cb)

get_value = (json, el) ->
  return json[el.mask]?.Value?[0]
get_values = (json, el) ->
  return json[el.mask]?.Value
get_vr = (json, el) ->
  return json[el.mask]?.vr

exports.Dicom2JsonTest =
  "test patient blob": (test) ->
    test.expect 2
    file2json "test/patient.blob", (err, json) ->
      if err
        console.error err
      test.equal "Agostini^Giacomo", get_value(json, tags.PatientName)
      test.equal "19870523", get_value(json, tags.PatientBirthDate)
      test.done()

  "test study blob": (test) ->
    test.expect 2
    file2json "test/study.blob", (err, json) ->
      if err
        console.error err
      test.equal "1.2.40.1.12.13589053", get_value(json, tags.StudyInstanceUID)
      test.equal "13589053", get_value(json, tags.AccessionNumber)
      test.done()

  "test series blob": (test) ->
    test.expect 2
    file2json "test/series.blob", (err, json) ->
      if err
        console.error err
      test.equal "1.3.12.2.1107.5.1.4.43511.30000005090506061531200001783", get_value(json, tags.SeriesInstanceUID)
      test.equal 1, get_values(json, tags.ReferencedPerformedProcedureStepSequence).length
      test.done()
