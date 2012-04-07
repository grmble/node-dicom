"use strict";

var assert = require('assert');
var util = require('util');
var printf = require('printf');

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

var DicomHandler = function (decoder) {
    this.elementStack = [];
    if (decoder) {
        this.registerDecoder(decoder);
    }
};

/**
 * Register with the decoder
 *
 */
DicomHandler.prototype.registerDecoder = function (decoder) {
    decoder.on('startElement', this.startElement.bind(this));
    decoder.on('endElement', this.startElement.bind(this));
    decoder.on('element', this.emitElement.bind(this));
    decoder.on('data', this.data.bind(this));
    decoder.on('start', this.emitStart.bind(this));
    decoder.on('end', this.emitEnd.bind(this));
};

/**
 * start an element.
 *
 * dataElement is a VR instance with rawValue missing.
 * nestingType must be one of SQ (for sequence), Item (for item),
 * or undefined.
 *
 * This maintains the elementStack and calls emitStartElement.
 */
DicomHandler.prototype.startElement = function (dataElement) {
    var type = dataElement.vr;
    assert.ok(!dataElement.rawValue);
    this.elementStack.push(dataElement);
    this.emitStartElement(dataElement);
};

/**
 *
 * get the current top element.
 *
 */
DicomHandler.prototype.currentElement = function () {
    return this.elementStack[this.elementStack.length - 1];
};

/**
 * end an element.
 *
 * ends the current top element.  checkType must be SQ for a sequence,
 * Item for an item, undefined for anything else.
 * 
 * this maintains the element stack, checks for nesting errors and calls
 * emitEndElement.
 */
DicomHandler.prototype.endElement = function (checkNesting) {
    var current = this.elementStack.pop();
    if (!current) {
        throw new Error("endElement - no current element");
    }

    if (current.vr === 'SQ' && checkNesting !== 'SQ') {
        throw new Error("endElement nesting mismatch - Sequence must be ended by SQ:" + checkNesting);
    } else if (current.tag === "(FFFE,E000)" && checkNesting !== 'Item') {
        throw new Error("endElement nesting mismatch - Item must be ended by Item:" + checkNesting);
    } else if (checkNesting) {
        throw new Error("endElement nesting mismatch - Non-SQ/Item must not be ended with checkNesting:" +
                checkNesting);
    }

    this.emitEndElement(current);
};

/**
 *
 * add data to the current top element.
 *
 * Top element may not be a sequence or item.
 */
DicomHandler.prototype.data = function (buffer) {
    var current = this.currentElement();
    if (current.vr === 'SQ' || current.tag === "(FFFE,E000)") {
        throw new Error("data - current element must not be Item or Sequence:" + current);
    }

    this.emitData(buffer);
};


exports.DicomHandler = DicomHandler;



/**
 *
 * XMLHandler
 *
 * turn dicom parsing events into dcm4che2 compatible xml.
 *
 */

var XMLHandler = function (decoder, stream) {
    DicomHandler.call(this, decoder);
    this.stream = stream;
};
util.inherits(XMLHandler, DicomHandler);

XMLHandler.prototype.emitStart = function () {
    this.stream.write("<dataset>\n");
};
XMLHandler.prototype.emitStartElement = function (dataElement) {
};
XMLHandler.prototype.emitEndElement = function (dataElement) {
};
XMLHandler.prototype.emitData = function (buffer) {
};
XMLHandler.prototype.emitElement = function (dataElement) {
    var tag = dataElement.tag.replace(/[^0-9a-fA-F]/g, '');
    var value = dataElement.decode()[0];
    if (value) {
        value = value.toString().replace(/\</g, '&lt;').replace(/\>/g, '&gt;');
    }
    var s = printf("<attr tag='%s'>%s</attr>\n", tag, value);
    this.stream.write(s);
};

XMLHandler.prototype.emitEnd = function () {
    this.stream.write("</dataset>\n");
    this.stream.end();
};

exports.XMLHandler = XMLHandler;
