#! /usr/bin/env coffee
#
# test the dicom decode / json pipeline
fs = require "fs"
zlib = require "zlib"

tags = require "../lib/tags"
decoder = require "../lib/decoder"
json = require "../lib/json"

exports.Dicom2JsonTest =
  "test defined length sequences/items": (test) ->
    test.expect 2
    json.gunzip2json "test/deflate_tests/report.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal 1111, json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeValue)
      test.equal "Consultation Report", json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeMeaning)
      test.done()

  "test undefined length sequences/items": (test) ->
    test.expect 2
    json.gunzip2json "test/report_undef_len.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal 1111, json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeValue)
      test.equal "Consultation Report", json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeMeaning)
      test.done()

  "test implicit vr little endian": (test) ->
    test.expect 2
    json.gunzip2json "test/report_default_ts.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal 1111, json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeValue)
      test.equal "Consultation Report", json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeMeaning)
      test.done()

  "test greek charset (isoir126)": (test) ->
    test.expect 1
    json.gunzip2json "test/charsettests/SCSGREEK.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal "Διονυσιος", json.get_value(data, tags.PatientName).Alphabetic
      test.done()

  "test utf8 charset": (test) ->
    test.expect 2
    json.gunzip2json "test/charsettests/SCSX1.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal "Wang^XiaoDong", json.get_value(data, tags.PatientName).Alphabetic
      test.equal "王^小東", json.get_value(data, tags.PatientName).Ideographic
      test.done()

  "test gb18030 charset": (test) ->
    test.expect 2
    json.gunzip2json "test/charsettests/SCSX2.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal "Wang^XiaoDong", json.get_value(data, tags.PatientName).Alphabetic
      test.equal "王^小东", json.get_value(data, tags.PatientName).Ideographic
      test.done()

  "test patient blob": (test) ->
    test.expect 2
    json.file2json "test/patient.blob", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.deepEqual {Alphabetic: "Agostini^Giacomo"}, json.get_value(data, tags.PatientName)
      test.equal "19870523", json.get_value(data, tags.PatientBirthDate)
      test.done()

  "test study blob": (test) ->
    test.expect 2
    json.file2json "test/study.blob", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal "1.2.40.1.12.13589053", json.get_value(data, tags.StudyInstanceUID)
      test.equal "13589053", json.get_value(data, tags.AccessionNumber)
      test.done()

  "test series blob": (test) ->
    test.expect 2
    json.file2json "test/series.blob", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal "1.3.12.2.1107.5.1.4.43511.30000005090506061531200001783", json.get_value(data, tags.SeriesInstanceUID)
      test.equal 1, json.get_values(data, tags.ReferencedPerformedProcedureStepSequence).length
      test.done()
