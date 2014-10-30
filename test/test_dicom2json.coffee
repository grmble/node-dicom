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
    test.expect 4
    json.gunzip2json "test/deflate_tests/report.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal 1111, json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeValue)
      test.equal "Consultation Report", json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeMeaning)

      # ContentSequence last item of 5 has BulkDataURI TextValue (among others)
      # offset 5562, length 268
      bd_elem = json.get_element(data, tags.ContentSequence, 4, tags.TextValue)
      bd = bd_elem.BulkDataURI
      test.ok /offset=5562\&/.test(bd)
      test.ok /length=268$/.test(bd)
      test.done()

  "test undefined length sequences/items": (test) ->
    test.expect 4
    json.gunzip2json "test/report_undef_len.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal 1111, json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeValue)
      test.equal "Consultation Report", json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeMeaning)
      #
      # ContentSequence last item of 5 has BulkDataURI TextValue (among others)
      # offset 6110, length 268
      bd_elem = json.get_element(data, tags.ContentSequence, 4, tags.TextValue)
      bd = bd_elem.BulkDataURI
      test.ok /offset=6110\&/.test(bd)
      test.ok /length=268$/.test(bd)
      test.done()

  "test implicit vr little endian": (test) ->
    test.expect 4
    json.gunzip2json "test/report_default_ts.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal 1111, json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeValue)
      test.equal "Consultation Report", json.get_value(data, tags.ConceptNameCodeSequence, 0, tags.CodeMeaning)
      #
      # ContentSequence last item of 5 has BulkDataURI TextValue (among others)
      # offset 5936, length 268
      bd_elem = json.get_element(data, tags.ContentSequence, 4, tags.TextValue)
      bd = bd_elem.BulkDataURI
      test.ok /offset=5936\&/.test(bd)
      test.ok /length=268$/.test(bd)
      test.done()

  "test greek charset (isoir126)": (test) ->
    test.expect 3
    json.gunzip2json "test/charsettests/SCSGREEK.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal "Διονυσιος", json.get_value(data, tags.PatientName).Alphabetic
      # PixelData native offset 866, length 262144
      bd_elem = json.get_element(data, tags.PixelData)
      bd = bd_elem.BulkDataURI
      test.ok /offset=866\&/.test(bd)
      test.ok /length=262144$/.test(bd)
      test.done()

  "test utf8 charset": (test) ->
    test.expect 4
    json.gunzip2json "test/charsettests/SCSX1.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal "Wang^XiaoDong", json.get_value(data, tags.PatientName).Alphabetic
      test.equal "王^小東", json.get_value(data, tags.PatientName).Ideographic

      # PixelData native offset 886, length 262144
      bd_elem = json.get_element(data, tags.PixelData)
      bd = bd_elem.BulkDataURI
      test.ok /offset=886\&/.test(bd)
      test.ok /length=262144$/.test(bd)
      test.done()

  "test gb18030 charset": (test) ->
    test.expect 4
    json.gunzip2json "test/charsettests/SCSX2.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal "Wang^XiaoDong", json.get_value(data, tags.PatientName).Alphabetic
      test.equal "王^小东", json.get_value(data, tags.PatientName).Ideographic

      # PixelData native offset 880, length 262144
      bd_elem = json.get_element(data, tags.PixelData)
      bd = bd_elem.BulkDataURI
      test.ok /offset=880\&/.test(bd)
      test.ok /length=262144$/.test(bd)
      test.done()

  "test quotes in json and encaps pixeldata": (test) ->
    test.expect 3
    json.gunzip2json {filename: "test/quotes_jpls.dcm.gz", bulkdata_uri: "\"D'Artagnan\""}, (err, data) ->
      if err
        console.log "Error:", err.stack
      test.deepEqual {Alphabetic: "\"D'Artagnan\"^asdf"}, json.get_value(data, tags.PatientName)

      # PixelData encapsulated fragment 1 offset 918, length 26272
      bd_elem = json.get_element(data, tags.PixelData)
      bd = bd_elem.DataFragment[1].BulkDataURI
      test.ok /offset=918\&/.test(bd)
      test.ok /length=26272$/.test(bd)
      test.done()

  "test inlinebinary ob": (test) ->
    test.expect 2
    json.gunzip2json "test/deflate_tests/report.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      elem = json.get_element(data, tags.FileMetaInformationVersion)
      test.ok not elem.Value?
      test.ok elem.InlineBinary
      test.done()


  "test decoding big endian": (test) ->
    test.expect 2
    json.gunzip2json "test/scsarab_be.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      test.equal 512, json.get_value(data, tags.Rows)
      test.equal 512, json.get_value(data, tags.Columns)
      test.done()


  "test decoding implicit vr with undefined length private sequence": (test) ->
    test.expect 4
    json.gunzip2json "test/private_report.gz", (err, data) ->
      if err
        console.log "Error:", err.stack
      elem = tags.for_tag(0x0041A730)
      test.equal 'UN', elem.vr
      priv_cont_sq = json.get_element(data, elem)
      # console.log "priv_cont_sq", priv_cont_sq
      test.ok priv_cont_sq
      test.equal 'SQ', priv_cont_sq.vr
      test.equal 5, priv_cont_sq.Value.length
      test.done()

  "test decoding implicit vr pixeldata": (test) ->
    test.expect 4
    json.gunzip2json "test/hebrew_ivrle.gz", (err, data) ->
      if err
        console.log "Error:", err.stack

      test.equal "שרון^דבורה", json.get_value(data, tags.PatientName).Alphabetic

      # PixelData native offset 848, length 262144
      bd_elem = json.get_element(data, tags.PixelData)
      bd = bd_elem.BulkDataURI
      test.ok /offset=848\&/.test(bd)
      test.ok /length=262144$/.test(bd)

      test.equal 'OW', bd_elem.vr
      test.done()



EMPTY_AT_EOF = """CAAFAENTCgBJU09fSVIgMTkyCAAgAERBAAAIADAAVE0AAAgAUABTSAAACABSAENTBgBTVFVEWSAI
AGEAQ1MAAAgAYgBVSQAACACQAFBOAAAIADAQTE8AABAAEABQTgAAEAAgAExPAAAQACEATE8AABAA
MABEQQAAEAAyAFRNAAAQAEAAQ1MAACAADQBVSQAAIAAQAFNIAAAgAAASSVMAACAAAhJJUwAAIAAE
EklTAAAgAAYSSVMAACAACBJJUwAA"""

exports.EmptyElementAtBufferEndTest =
  "test empty element at buffer end": (test) ->
    test.expect 4
    _buff = new Buffer(EMPTY_AT_EOF, "base64")
    _dec = json.decoder2json transfer_syntax: 'ExplicitVRLittleEndian', (err, _json) ->
      throw err if err
      console.log "RESULT:", _json
      test.ok _json, "Test that we got a djm result"
      # test that we parsed a valueless element
      test.deepEqual [], json.get_values(_json, tags.NumberOfStudyRelatedInstances)
      test.equal null, json.get_value(_json, tags.NumberOfStudyRelatedInstances)
      test.equal null, json.get_value(_json, tags.PatientName)
      test.done()
    _dec.end(_buff)