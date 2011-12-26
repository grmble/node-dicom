/**
 *
 * Asynchronous DICOM Decoder
 *
 */

var Binary = require('binary')
    , Hash = require('hashish')
    , EventEmitter = require('events').EventEmitter
    , util = require('util')
    , assert = require('assert')
    , VR = require('./vr')
    , helper = require('./helper')
    , SimpleTree = require('./dicom-tree').SimpleTree


/*
 *
 * fake Binary methods
 *
 * these are bound to the Binary object
 */
function decodePreamble(decoder) {
    return this.buffer('preamble', 128)
        .tap(emitter(decoder, 'preamble'))
        .flush()
}

function decodeDicomPrefix(decoder) {
    return this.buffer('dicomprefix', 4)
        .tap(emitter(decoder, 'dicomprefix', buffer2latin1))
        .flush()
}

/**
 *
 * decode one dataelement
 *
 */
function decodeDataElement(decoder) {
    var vr = null
        , endianess = decoder.endianess
        , w16u = endianess.word16u
        , w32u = endianess.word32u

    return helper.chainCall(this
            , [w16u, 'group']
            , [w16u, 'element']
            , [this.buffer, 'vr', 2]
            , [this.tap, function (vars) {
                var vrStr = buffer2latin1(vars.vr)
                console.log("VR STRING READ:", vrStr)
                vr = endianess[vrStr]
                var bytes = vr.valueLengthBytes(decoder.implicit)
                console.log("number of bytes", bytes)
                switch(bytes) {
                    case 2: return w16u.call(this, 'len')
                    case 4: return w32u.call(this, 'len')
                    case 6: return w32u.call(this.skip(2), 'len')
                }}]
            , [this.tap, function(vars) {console.log("LEN:", vars.len)}]
            // XXX: SEQUENCE PARSING - UNDELIMITED LENGTH
            , [this.buffer, 'value', 'len']
            , [this.tap, function (vars) {
                var tag = (vars.group << 16) ^ vars.element
                console.log("emitting dataelement:", tag.toString(16), vr, vars.value)
                decoder.emit('dataelement', tag, vr, vars.value)
            }]).flush()
}

/**
 *
 * decode a block of dataelements of length blocklength
 *
 */
function decodeDataElementBlock(decoder, blockLength) {
    var startPosition, endPosition
    return this
        .tap(function () {
            startPosition = this.currentPosition()
            endPosition = startPosition + blockLength
            console.log("decodeDataElementBlock startPosition " + startPosition);
            console.log("decodeDataElementBlock endPosition " + endPosition);
        }).loop(function (end, vars) {
            var currPos = this.currentPosition()
            console.log("decodeDataElementBlock: " + currPos)
            if (this.currentPosition() >= endPosition) {
                end()
            } else {
                decodeDataElement.call(this, decoder)
            }
        })
}

// this actually emits the first non-metadata dataelement
// the transfer syntax switch is done correctly (knockknock)
// but this allows us not to mark/reset the stream
// the non-metadata implementation is faster though because
// we don't have to code for a transfer syntax switch
function decodeMetaInfo(decoder) {
    console.log("meta info ...")

    var metainfo = new SimpleTree(decoder)
        , metainfoLength

    return helper.chainCall(this
            , [decodeDataElement, decoder] // read 1 data element
            , [this.tap, function (vars) {
                metainfoLength = metainfo.getValue(0x20000)
                assert.ok(metainfoLength, "MUST HAVE 0x20000 at start of metainfo")
                console.log("decoded meta info length:" + metainfoLength)
            }]
            , [decodeDataElementBlock, decoder, metainfoLength]
            , [this.tap, function (vars) {
                metainfo.removeListeners()
            }])
}

/* all of the above ;) */
function decodeFileMetaInfo(decoder) {
    return helper.chainCall(this
            , [decodePreamble, decoder]
            , [decodeDicomPrefix, decoder]
            , [decodeMetaInfo, decoder])
}


function decodeDataset(decoder) {
    return this.loop(function (end, vars) {
        console.log("decode dataset loop ....");
        return decodeDataElement.call(this, decoder)
    })
}

/**
 *
 * create emitter function
 *
 *
 */
function emitter (decoder, key, fn) {
    return function (vars) {
        var what = vars[key]
        if (fn !== undefined) {
            what = fn(what)
        }
        console.log("emitting to decoder", key, what)
        decoder.emit(key, what)
    }
}

/**
 * emitter mappers
 */
function buffer2latin1 (buffer) {
    return buffer.toString('binary')
}


exports.DicomDecoder = function(streamOrBuffer, options) {
    var defaultOptions = {
        fileMetaInfo: true /* decode dicom meta info header */
    }, decoder = this
    , options = Hash.merge(defaultOptions, options || {})
    , binary = new Binary(streamOrBuffer)

    decoder.endianess = VR.LE
    decoder.implicit = false
    decoder.nextTransferSyntax = null
    decoder.metaInfoDone = false

    binary
        .tap(function () { if (options.fileMetaInfo) decodeFileMetaInfo.call(this, decoder) })
        .tap(function() { decodeDataset.call(this, decoder) })
                    
}
util.inherits(exports.DicomDecoder, EventEmitter)

/**
 * switch to transfersyntax that has been previously set
 */
exports.DicomDecoder.prototype.switchTransferSyntax = function () {
    console.log("switching transfer syntax .... XXX implement")
    this.metaInfoDone = true
} 


var DICOM_INPUT = "/opt/share/TESTDATA/agostini_giacomo/1B3D1BD1/15C540E7/95750D3B"
var decoder = new exports.DicomDecoder(require('fs').createReadStream(DICOM_INPUT, {bufferSize: 4096}))

