Node.js DICOM Decoding
======================

Data dictionary according to the 2014 standard.

Currently, there is a Decoder that turns a DICOM stream
into Dicom Events.  A JsonEncoder can produce a
DICOM JSON Model from this.

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

    print_element = (json, el) ->
      console.log el.name, json[el.mask]

    require("fs").createReadStream(process.argv[2]).pipe decoder
    .pipe encoder
    .pipe sink

Or the same in Javascript:


    var dicom = require("dicom");

    var print_element = function(json, el) {
    return console.log(el.name, json[el.mask]);
    };

    var decoder = dicom.decoder({
    guess_header: true
    });

    var encoder = new dicom.json.JsonEncoder();

    var sink = new dicom.json.JsonSink(function(err, json) {
    if (err) {
      console.log("Error:", err);
      process.exit(10);
    }
    print_element(json, dicom.tags.PatientID);
    print_element(json, dicom.tags.IssuerOfPatientID);
    print_element(json, dicom.tags.StudyInstanceUID);
    return print_element(json, dicom.tags.AccessionNumber);
    });

    require("fs").createReadStream(process.argv[2]).pipe(decoder).pipe(encoder).pipe(sink);
