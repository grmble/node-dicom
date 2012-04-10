"use strict";

var assert = require('assert'),
    util = require('util'),
    EventEmitter = require('events').EventEmitter,
    printf = require('printf'),
    log4js = require('log4js'),
    fs = require('fs'),
    tags = require('./tags'),
    vr = require('./vr'),
    DicomReader = require('./dicomreader').DicomReader;

var verbose = true;
var log = log4js.getLogger("json");

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

/**
 *
 * Emit parse events from an  object as returned by JsonHandler
 *
 */
var ObjectEmitter = function (obj) {
    EventEmitter.call(this);
    this.obj = obj;
};
util.inherits(ObjectEmitter, EventEmitter);

ObjectEmitter.prototype.error = function (err) {
    this.emit('error', err);
};

ObjectEmitter.prototype.emitEvents = function () {
    /*jslint undef: true */
    var self = this,
        recurse = function (obj) {
            var k, v, i, len, tag, elem, objTags = [];
            for (k in obj) {
                if (obj.hasOwnProperty(k)) {
                    tag = tags.byName[k] || tags.tag(k);
                    if (!tag) {
                        self.error(new Error("Not in data dictionary:" + k));
                    } else {
                        objTags.push(tag.tag);
                    }
                }
            }
            objTags.sort();
            for (k = 0; k < objTags.length; k += 1) {
                vtrace("ObjectEmitter sorted tag:", objTags[k]);
                v = obj[objTags[k]];
                tag = tags.tag(objTags[k]);
                elem = new vr.LE[tag.vr]();
                elem.tag = tag.tag;
                vtrace("ObjectEmitter emitting element", elem);
                self.emit('element', elem);
                if (elem.vr === 'SQ') {
                    assert.ok(util.isArray(v));
                    len = v.length;
                    for (i = 0; i < len; i += 1) {
                        emitItem(v[i]);
                    }
                } else {
                    // XXX encode before emit
                    vtrace("ObjectEmitter emitting data", v);
                    self.emit('data', v);
                }
                vtrace("ObjectEmitter emitting endElement", elem);
                self.emit('endElement', elem);
            }
        },
        emitItem = function (item) {
            var elem = new vr.LE.NoVR();
            elem.tag = tags.Item;
            vtrace("ObjectEmitter item", elem);
            self.emit('element', elem);
            recurse(item);
            vtrace("ObjectEmitter end item", elem);
            self.emit('endElement', elem);
        };

    recurse(self.obj);
    self.emit('end');
};

exports.ObjectEmitter = ObjectEmitter;

if (require.main === module) {
    var stream = fs.createReadStream(process.argv[2]);
    var dr = new DicomReader(stream);
    var handler = new JsonHandler(dr);
    dr.readDataset(function () {
        console.log(handler.json());
    });
}
