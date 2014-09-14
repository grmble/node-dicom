dicom.json.sink(3) - Dicom JSON Sink
====================================

##SYNOPSIS

    var sink = dicom.json.sink(function(err, data) {
      // data contains the parsed JSON model
    });

##DESCRIPTION

`JsonSink` is a transform stream that collects the JSON chunks emitted
by `dicom.json.encoder` and parses the result.

The supplied callback will be called with an error or
the parsed JSON as the second argument.


##SEE ALSO
* dicom.json
* dicom.json.encoder
