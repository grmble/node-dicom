#! /usr/bin/env node

"use strict";

var uids = require('../lib/uids'),
    argv = require('optimist')
    .boolean('f')
    .usage('Find DICOM UIDs.\nUsage: $0 [-f] uid [uid ...]')
    .describe('f', 'fgrep like non-regexp search terms')
    .demand(1)
    .argv;

argv._.forEach(function (what) {
    uids.find(argv.f ? what : new RegExp(what, "i"));
});
