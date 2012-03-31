#! /usr/bin/env node

"use strict";

var tags = require('../lib/tags'),
    argv = require('optimist')
    .boolean('f')
    .usage('Usage: $0 [-f] tag [tag2 ...]')
    .describe('f', 'fgrep like non-regexp search terms')
    .demand(1)
    .argv;

argv._.forEach(function (what) {
    tags.find(argv.f ? what : new RegExp(what, "i"));
});
