#! /usr/bin/env /coffee

json = require "../lib/json"

DATA = {
  "00100020": {vr: "LO", Value: ["007"]},
  "00100021": {vr: "LO", Value: ["MI6"]},
  "00101002": {vr: "SQ", Value: [{
     "00100020": {vr: "LO", Value: ["0815"]},
     "00100021": {vr: "LO", Value: ["BND"]}}
  ]}}

SIMPLE = {
  "PatientID": "007",
  "IssuerOfPatientID": "MI6",
  "OtherPatientIDsSequence": [{
    "PatientID": "0815",
    "IssuerOfPatientID": "BND"}]}

exports.Json2JsonTest =
  "test simplified json model": (test) ->
    test.expect 1
      
    callback = (err, data) ->
      if err
        console.error "Error:", err
        console.error "stack trace:", err.stack
        throw err
      test.deepEqual DATA, data
      test.done()

    source = new json.JsonSource(SIMPLE)
    .on 'error', callback
    .pipe new json.JsonEncoder({})
    .on 'error', callback
    .pipe new json.JsonSink(callback)

