/**
 *
 * build a tree structure from dicom decoding events
 *
 */

exports.SimpleTree = function(decoder) {
    var tree = {}
    this.tree = tree
    this.decoder = decoder
    this.onDataElementListener = function(tag, vr, buffer) {
        console.log("SimpleTree: on Dataelement: ", tag, vr, buffer)
        tree[tag] = vr.decode(buffer)
    }

    decoder.on('dataelement', this.onDataElementListener)
}

exports.SimpleTree.prototype.getValue = function (tag) {
    var v = this.tree[tag]
    if(v === undefined) {
        return v
    }

    return v[0]
}

exports.SimpleTree.prototype.getValues = function (tag) {
    return this.tree[tag]
}

exports.SimpleTree.prototype.removeListeners = function () {
    this.decoder.remoteListener(this.onDataElementListener)
}


