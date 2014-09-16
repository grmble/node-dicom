dicom.json.source(3) - Dicom JSON Source
========================================

##SYNOPSIS

  data = {
    "00100020": {vr: "LO", Value: ["007"]},
    "00100021": {vr: "LO", Value: ["MI6"]},
    "00101002": {vr: "SQ", Value: [{
       "00100020": {vr: "LO", Value: ["0815"]},
       "00100021": {vr: "LO", Value: ["BND"]}}
    ]}}
    var source = dicom.json.source(source, {transfer_syntax: "ExplicitVRLittleEndian"});
    source.pipe(...);

##DESCRIPTION

`JsonSource` is a readable stream that emits `DicomEvent`s from
a Dicom JSON Model.

For details on the Dicom JSON Model, see
http://medical.nema.org/dicom/2013/output/chtml/part18/sect_F.2.html

Additionaly, the JSON model is normalized before emitting data,
it may be given in a simplified form:

This means:
* Dicom tags are processed by `tags.for_tag`, this means you can
  specify them as `tags.PatientName` (this might give you tab completion),
  by their name (`"PatientName"`) or using their 8-digit hex representation
  (`"00100010"`).
* `vr` may be omitted, the vr from the element dictionary will be used.
* Instead of an object with `vr` and `Value`, you can only give the
  `Value` array
* A single string or number will be interpreted a single-value value.

As an example, the short JSON model from above can also be given as:

    {"PatientID": "007",
    "IssuerOfPatientID": "MI6",
    "OtherPatientIDsSequence": [{
      "PatientID": "0815",
      "IssuerOfPatientID": "BND"}]}


##Limitations
`JsonSource` can not handle a JSON model with BulkDataURI data.

Using a simplified JSON model is only possible in javascript source code,
as it is not legal JSON.


##SEE ALSO
* dicom.json
* dicom.json.encoder
