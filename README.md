Node.js DICOM Decoding
======================

Data dictionary according to the 2014 standard.

Currently, there is a Decoder that turns a DICOM stream
into Dicom Events.  A JsonEncoder can produce a
DICOM JSON Model from this.

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
