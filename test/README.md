Source of the various test images
=================================

All test images have been compressed with gzip (yes, even the already deflated test images;
it allows us to simply gunzip all test images, no special handling necessary).

* `charsettests`: `http://www.dclunie.com/images/charset/charsettests.20070405.tar.bz2`
* `deflate_tests`: `http://www.dclunie.com/images/compressed/deflate_tests_release.tar.gz`
* `report_undef_len.gz`: converted `deflate_tests/report.gz` to undefined
  length sequences / items
* `report_default_ts.gz`: converted `deflate_tests/report.gz` to
  ImplicitVRLittleEndian
* `private_report.gz`: `report.gz` with ContentSequence modified to a private Tag
* `hebrew_ivrle.gz`: converted `charsettests/SCSHBRW.gz` to ImplicitVRLittleEndian
* `quotes_jpls.dcm.gz`: converted `charsettests/SCSFR.gz` to JpegLS,
  and a patientname with single and double quotes in it
* `scsarab_be.gz`: converted `charsettests/SCSARAB.gz` to ExplictVRBigEndian
