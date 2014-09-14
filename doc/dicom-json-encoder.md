dicom.json.encoder(3) - Dicom JSON Model Encoder
================================================

##SYNOPSIS

    var encoder = dicom.json.encoder({bulkdata_uri: "file:///tmp/x.dcm"});

##DESCRIPTION

`JsonEncoder` is a transform stream that takes a stream of DicomEvent instances
and produces chunks of JSON.

`start_element`/`end_element` blocks produced by `dicom.decoder`
are emitted as bulkdata uri elements, so you can't get at that data
anymore except by parsing the uri and going to the original input.

If no `bulkdata_uri` is given, bulkdata elements will not be emitted at all.


##DETAILS

The Dicom JSON Model is defined at
http://medical.nema.org/dicom/2013/output/chtml/part18/sect_F.2.html

##SEE ALSO
* dicom.decoder
* dicom.json.sink
* dicom.json
