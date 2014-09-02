Node.js DICOM
=============

The package provides the following:

* Data dictionary according to the 2014a standard.
* Streaming DICOM Decoder that reads a DICOM stream end
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
  currently ignores these bulkdata stream parts.

Examples:
---------

The examples given here will not work if
you installed via npm.  The README for 
the last npm release is at
https://github.com/grmble/node-dicom/tree/e145f6c4b6e31e19d73e20777bda8c656996a4b2

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
