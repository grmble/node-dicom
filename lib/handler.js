"use strict";

var assert = require('assert'),
    util = require('util'),
    printf = require('printf'),
    fs = require('fs'),
    tags = require('./tags'),
    delay =  require('./delay'),
    DicomReader = require('./dicomreader').DicomReader;

var verbose = false;

var vtrace = function () {
    if (verbose) {
        console.log.apply(console.log, arguments);
    }
};

/**
 *
 * Basic Handler for Dicom Decoder Events
 *
 * this keeps track of a stack of incoming data elements 
 * (non-leafs are always SQ elements).
 *
 *
 * Note that there are 2 ways to emit elements:
 *
 * nesting and/or very long elements are emitted
 * with startElement, data/nested elements and endElement.
 *
 * Shorter elements with actual data my be emitted directly
 * via emitElement.
 *
 */

var DicomHandler = function (dicomreader, cont) {
    this.nested = [];
    this.cont = cont;
    if (dicomreader) {
        this.registerDicomReader(dicomreader);
    }
};

DicomHandler.prototype.registerDicomReader = function (dicomreader) {
    dicomreader.on('element', this.onElement.bind(this));
    dicomreader.on('endelement', this.onEndElement.bind(this));
    dicomreader.on('data', this.onData.bind(this));
    dicomreader.on('end', this.onEnd.bind(this));
};

DicomHandler.prototype.onElement = function (dataElement) {
    this.nested.push(dataElement);
    assert.ok(!dataElement.rawValue);
    this.emitElement(dataElement);
};

DicomHandler.prototype.onEndElement = function (dataElement) {
    this.nested.pop();
    this.emitEndElement(dataElement);
};

DicomHandler.prototype.currentElement = function () {
    var nested = this.nested;
    return nested[nested.length - 1];
};

DicomHandler.prototype.onData = function (buffer) {
    var current = this.currentElement();
    this.emitData(current, buffer);
};


exports.DicomHandler = DicomHandler;



var JsonHandler = function (dicomreader, cont) {
    DicomHandler.call(this, dicomreader, cont);
    this.nestedJson = [{}];
};
util.inherits(JsonHandler, DicomHandler);

JsonHandler.prototype.currentJson = function () {
    var json = this.nestedJson;
    return json[json.length - 1];
};

JsonHandler.prototype.emitElement = function (dataElement) {
    var current = this.currentJson(),
        newObj;
    if (dataElement.vr === 'SQ') {
        newObj = [];
        current[dataElement.tag] = newObj;
        this.nestedJson.push(newObj);
    } else if (dataElement.tag === tags.Item) {
        assert.ok(util.isArray(current));
        newObj = {};
        current.push(newObj);
        this.nestedJson.push(newObj);
    }
};

JsonHandler.prototype.emitData = function (dataElement, buffer) {
    dataElement.pushRaw(buffer);
};

JsonHandler.prototype.emitEndElement = function (dataElement) {
    var current;
    if (dataElement.vr === 'SQ' || dataElement.tag === tags.Item) {
        vtrace("popping nested json");
        this.nestedJson.pop();
    } else {
        dataElement.combineRaws();
        vtrace("JsonHandler.emitEndElement: combined values:", dataElement.values());
        current = this.currentJson();
        current[dataElement.tag] = dataElement.values();
    }
};

JsonHandler.prototype.onEnd = function () {
    var self = this;
    this.cont(self.nestedJson[0]);
};


if (require.main === module) {
    var stream = fs.createReadStream(process.argv[2]);
    var dr = new DicomReader(stream);
    var handler = new JsonHandler(dr, function (json) {
        console.log(util.inspect(json, false, null));
    });
    dr.readDataset(console.log);
}
