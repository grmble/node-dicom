"use strict";

var assert = require('assert'),
    util = require('util'),
    printf = require('printf'),
    log4js = require('log4js'),
    fs = require('fs'),
    tags = require('./tags'),
    DicomReader = require('./dicomreader').DicomReader;

var verbose = false;
var log = log4js.getLogger("handler");

var vtrace = function () {
    if (verbose && log.isDebugEnabled()) {
        log.debug.apply(log, arguments);
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

var DicomHandler = function (dicomreader) {
    this.nested = [];
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



var JsonHandler = function (dicomreader) {
    DicomHandler.call(this, dicomreader);
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
    if (dataElement.vr === 'SQ' || dataElement.encapsulated) {
        vtrace("JsonHandler.emitelement: pushing new []");
        newObj = [];
        current[dataElement.tag] = newObj;
        this.nestedJson.push(newObj);
    } else if (dataElement.tag === tags.Item) {
        assert.ok(util.isArray(current));
        vtrace("JsonHandler.emitelement: pushing new {}");
        newObj = {};
        current.push(newObj);
        this.nestedJson.push(newObj);
    }
};

JsonHandler.prototype.emitData = function (dataElement, buffer) {
    vtrace("JsonHandler.emitData", dataElement, buffer);
    dataElement.pushRaw(buffer);
};

JsonHandler.prototype.emitEndElement = function (dataElement) {
    var current;
    if (dataElement.nesting || dataElement.encapsulated) {
        vtrace("popping nested json");
        this.nestedJson.pop();
    } else {
        dataElement.combineRaws();
        vtrace("JsonHandler.emitEndElement: combined values:", dataElement.values());
        current = this.currentJson();
        current[dataElement.tag] = dataElement.values();
        vtrace("JsonHandler.emitEndElement: current", current);

        if (dataElement.tag === tags.Item && dataElement.valueLength !== undefined) {
            // this is an encapsulated item in the pixel data, we need to pop
            vtrace("JsonHandler.emitEndElement: popping encapsulated item");
            this.nestedJson.pop();
        }
    }
};

JsonHandler.prototype.onEnd = function () {
    var self = this;
};

JsonHandler.prototype.tree = function () {
    return this.nestedJson[0];
};

JsonHandler.prototype.json = function () {
    return util.inspect(this.tree(), false, null);
};

exports.JsonHandler = JsonHandler;

if (require.main === module) {
    var stream = fs.createReadStream(process.argv[2]);
    var dr = new DicomReader(stream);
    var handler = new JsonHandler(dr);
    dr.readDataset(function () {
        console.log(handler.json());
    });
}
