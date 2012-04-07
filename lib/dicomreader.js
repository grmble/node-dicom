"use strict";

/*jslint nomen: true */

var util = require('util'),
    ReadBuffer = require('./readbuffer').ReadBuffer,
    delay = require('./delay');


var verbose = true;
var vtrace = delay.logFn(verbose, console.log);


