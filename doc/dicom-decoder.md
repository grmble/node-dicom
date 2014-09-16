dicom.decoder(3) - Dicom Decoder
================================

##SYNOPSIS

    var decoder = dicom.decoder(options);

##DESCRIPTION

`dicom.decoder` is a transform stream that takes a DICOM file
and outputs `DicomEvent`s.

Valid options are:
* `streaming_value_length_minimum`: minimum value length, longer values will be
  streamed out.  I.e. the element is not constructed in memory and then emitted,
  but rather a `start_element` event is emitted, a number of raw events with
  the DICOM encoded content is emitted, and finally an `end_element` is emitted.
  This serves to reduce memory footprint, assuming that we are only really
  interested in the shorter elements (e.g. for putting them into a database),
  while allowing us to stream the dicom contents on (e.g. to store them in a file).

* `read_header`: read preamble / dicom header, defaults to false.
  This also implied reading metainfo with a transfer syntax switch.
* `transfer_syntax`: transfer syntax, defaults to `ExplicitVRLittleEndian`.
* `guess_header`: if true, the decoder will the to guess the encoding.
  First it will try to find a DICOM header (`DICM` at position 128),
  if that fails it will try to recognize a `SpecificCharacterSet` tag
  at the start of the file.

##SEE ALSO
* dicom.json.encoder
* dicom.encoder
