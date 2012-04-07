#! /usr/bin/env node
"use strict";

var decoder = require('../lib/decoder'),
    handler = require('../lib/handler'),
    fs = require('fs'),
    log4js = require('log4js'),
    log = log4js.getLogger('dicom-xml');

if (require.main === module) {
    var DICOM_INPUT = "/opt/share/TESTDATA/agostini_giacomo/1B3D1BD1/15C540E7/95750D3B";
    var stream = fs.createReadStream(DICOM_INPUT);
    var outStream = fs.createWriteStream("/tmp/x.x");
    var decoder = new decoder.DicomDecoder(stream),
        xmlhandler = new handler.XMLHandler(decoder, outStream),
        t1;


    decoder.decodePreamble();
    decoder.decodeDicomPrefix();

    t1 = new Date().getTime();
    decoder.decodeMetaInfo(function () {
        var t2 = new Date().getTime();
        log.debug("decodeMetaInfo done in", t2 - t1);
        decoder.decode(function () {
            var t3 = new Date().getTime();
            log.debug("Total decode done in", t3 - t1);
        });
    });
}

