Node.js DICOM
=============

[![Build Status](https://travis-ci.org/grmble/node-dicom.svg?branch=master)](https://travis-ci.org/grmble/node-dicom)

The package provides the following:

* Data dictionary according to the 2014a standard.
* Streaming DICOM Decoder that reads a DICOM stream and
  emits DicomEvent instances.
* Streaming JSON Encoder that turns a DicomEvent stream
  into a DICOM JSON Model
* JSON Sink that consumes the JSON Model stream and
  produces an in-memory JSON Object.

Limitations:
------------

* ISO 2022 character sets are not in iconv-lite,
  this means the decoder does not currently
  support ISO 2022 encodings,
  multi-valued (0008,0005) Specific Character Set
  and DICOM characterset extensions.
* Dicom Elements with a value length above a
  configurable threshold are not constructed
  in-memory, but emitted as `start_element`,
  a sequence of raw events with the encoded value
  and an `end_element` event.  The JSON Encoder 
  emits these as bulkdata URLs, but currently
  there is no way to use these urls (except parsing
  the url and extracting the bulkdata using
  offset and length from the url).
* `Other` DICOM VRs (`OB`, `OW`, `OF`, `OD`, `UN`)
  do not provide a way to interpret the data,
  i.e. it's just passed on as a byte array, unchanged.

Examples:
---------

Read a DICOM file, produce JSON Model, and print some data:

    dicom = require "dicom"

    decoder = dicom.decoder {guess_header: true}
    encoder = new dicom.json.JsonEncoder()
    sink = new dicom.json.JsonSink (err, json) ->
      if err
        console.log "Error:", err
        process.exit 10
      print_element json, dicom.tags.PatientID
      print_element json, dicom.tags.IssuerOfPatientID
      print_element json, dicom.tags.StudyInstanceUID
      print_element json, dicom.tags.AccessionNumber

    print_element = (json, path...) ->
      console.log dicom.json.get_value(json, path...)

    require("fs").createReadStream(process.argv[2]).pipe decoder
    .pipe encoder
    .pipe sink


And the same thing in Javascript:

    "use strict";

    var dicom = require("dicom");

    var decoder = dicom.decoder({
        guess_header: true
    });

    var encoder = new dicom.json.JsonEncoder();

    var print_element = function(json, elem) {
        console.log(dicom.json.get_value(json, elem));
    };

    var sink = new dicom.json.JsonSink(function(err, json) {
        if (err) {
          console.log("Error:", err);
          process.exit(10);
        }
        print_element(json, dicom.tags.PatientID);
        print_element(json, dicom.tags.IssuerOfPatientID);
        print_element(json, dicom.tags.StudyInstanceUID);
        print_element(json, dicom.tags.AccessionNumber);
    });

    require("fs").createReadStream(process.argv[2]).pipe(decoder).pipe(encoder).pipe(sink);
