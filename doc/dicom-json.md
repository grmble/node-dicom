dicom.json(3) - Dicom JSON Model utilities
===========================================

##SYNOPSIS

    file2json("/tmp/example.dcm", err_data_cb);
    gunzip2json("/tmp/example.dcm.gz", err_data_cb);
    file2jsonstream("/tmp/example.dcm", err_data_cb).pipe(dicom.json.sink(err_data_cb));
    gunzip2jsonstream("/tmp/example.dcm.gz", err_data_cb).pipe(dicom.json.sink(err_data_cb));

    // in a callback with parsed json
    var el = dicom.json.get_element(data, dicom.tags.StudyInstanceUID);
    var val = dicom.json.get_value(data, dicom.tags.StudyInstanceUID);
    var vr = dicom.json.get_vr(data, dicom.tags.StudyInstanceUID);

##DESCRIPTION

###Pipe helpers
`file2json` and `gunzip2json` set up the whole pipeline from a
(gzipped) file to parsed Dicom JSON Model.  They also take care
to pass errors along to the supplied callback.

`file2jsonstream` and `gunzip2jsonstream` set up the pipeline
only until `dicom.json.JsonEncoder`, e.g. for writing JSON to a
file or a network socket.

These 4 functions take the following arguments:

* `filename`: a filename (string) or a filename specifier,
  an object with the properties `.filename` and `.bulkdata_uri`.
  A string filename will be re-used as `bulkdata_uri`.
* `callback`: standard node callback, error or parsed json data.
  The 2 streaming calls will only call the callback on error.

###JSON Model helpers

Helper functions are provided to access the data in the JSON Model.

A short example (of a much, much larger file) to show why this might be needed:

    {"20010010": {"vr":"LO","Value":["Philips Imaging DD 001"]},
    "20010090": {"vr":"LO","Value":["Philips Imaging DD 129"]},
    "20011063": {"vr":"UN","InlineBinary":["UklTIA=="]},
    "2001106E": {"vr":"UN","BulkDataURI":"xxx?offset=6290&length=666"},
    "20019000": {"vr":"SQ", "Value": [{
     "00080000": {"vr":"UL","Value":[350]},
     "00080016": {"vr":"UI","Value":["1.2.840.10008.5.1.4.1.1.11.1"]},
     "00080018": {"vr":"UI","Value":["1.3.46.670589.30.1.6.1.963334011378.1349417319250.1"]},
     "00081115": {"vr":"SQ", "Value": [{
      "00080000": {"vr":"UL","Value":[138]},
      "00081140": {"vr":"SQ", "Value": [{
       "00080000": {"vr":"UL","Value":[94]},
       "00081150": {"vr":"UI","Value":["1.2.840.10008.5.1.4.1.1.1"]},
       "00081155": {"vr":"UI","Value":["1.3.46.670589.30.1.6.1.963334011378.1349417318484.2"]}}]},
      "00200000": {"vr":"UL","Value":[60]},
      "0020000E": {"vr":"UI","Value":["1.3.46.670589.30.1.6.1.963334011378.1349417318546.1"]}}]}}]}}

`get_element(data, list_of_tags_or_item_idx)` gives you access
to an element in a potentially deeply nested structure.  Numbers
are taken to be indexes to multiple values (in nested `SQ` elements),
while anything else is supposed to be a tag (see `dicom.tags.for_tag`).

`get_values(data, list_of_tags_or_item_idx)` does the same,
but gives you the final `Value` property.

`get_value(data, list_of_tags_or_item_idx)` gives you the first element of
the `Value` property.

`get_vr(data, ....)` gives you the `vr`.

##DETAILS

###Dicom JSON Model

The Dicom JSON Model is defined at
http://medical.nema.org/dicom/2013/output/chtml/part18/sect_F.2.html

##SEE ALSO
* dicom.decoder
* dicom.json.encoder
* dicom.json.sink
