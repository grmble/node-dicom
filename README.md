[![build status](https://secure.travis-ci.org/grmble/node-dicom.png)](http://travis-ci.org/grmble/node-dicom)
Node.js DICOM Parser
====================

There is a data dictionary that knows about the tag definitions
and UIDs of the 2011 standard.  The DICOM parser parses every string as Latin-1
i.e it is not aware of SpecificCharacterSet.  The parser emits events that can
be used to produce any kind of output.  Currently only JSON is produced.

Examples:
---------

Read a dicom file in ExplictVRLittleEndian - no preamble or metainfo, just the dataset.

    var fs = require('fs'),
        dicom = require('node-dicom');

    var stream = fs.createReadStream(process.argv[2]),
        reader = new dicom.dicomreader.DicomReader(stream),
        handler = new dicom.handler.JsonHandler(reader);
    reader.readDataset(function () {
        console.log("Dataset: %s", handler.json());
    });


Read a DICOM file with preamble & metainfo giving the TS for the main dataset:


    var fs = require('fs'),
        dicom = require('node-dicom');


    var stream = fs.createReadStream(process.argv[2]),
        reader = new dicom.dicomreader.DicomReader(stream),
        handler = new dicom.handler.JsonHandler(reader);
    reader.readFile(function () {
        console.log("Dataset: %s", handler.json());
    });


