"use strict";
/*jslint nomen: true */

/*
 *
 * contents of patient.blob
(0008,0005) CS #10 [ISO_IR 100] Specific Character Set
(0008,1120) SQ #-1 [1 item] Referenced Patient Sequence
>ITEM #1 @30:
>(0008,1150) UI #0 [] Referenced SOP Class UID
>(0008,1155) UI #0 [] Referenced SOP Instance UID
(0010,0010) PN #16 [Agostini^Giacomo] Patient's Name
(0010,0020) LO #2 [P2] Patient ID
(0010,0021) LO #8 [MINIRIS] Issuer of Patient ID
(0010,0030) DA #8 [19870523] Patient's Birth Date
(0010,0040) CS #2 [M] Patient's Sex
*/

var fs = require('fs'),
    path = require('path'),
    DicomReader = require('../lib/dicomreader').DicomReader,
    JsonHandler = require('../lib/handler').JsonHandler;


exports.testReadDataset = function (test) {
    test.expect(1);
    var result = {
        '(0008,0005)': ['ISO_IR 100'],
        '(0008,1120)': [{'(0008,1150)': [], '(0008,1155)': []}],
        '(0010,0010)': ['Agostini^Giacomo'],
        '(0010,0020)': ['P2'],
        '(0010,0021)': ['MINIRIS'],
        '(0010,0030)': ['19870523'],
        '(0010,0040)': ['M']
    }, stream = fs.createReadStream(path.join(__dirname, "patient.blob")),
        reader = new DicomReader(stream),
        handler = new JsonHandler(reader);
    reader.readDataset(function () {
        test.deepEqual(result, handler.tree());
        test.done();
    });

};
