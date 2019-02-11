#──────────────────────────────────────────────────────
# Globals for mocha testing
#──────────────────────────────────────────────────────
console.log("Loading mocha settings from `test/global.coffee`")

# Include common testing modules
_ = global._ = require 'underscore'

jsdom = global.jsdom = require 'jsdom'
{JSDOM} = jsdom

global.JSDOM = JSDOM;
dom = global.dom = new JSDOM "<!DOCTYPE html><html><head></head><body></body></html>";
window = global.window = dom.window
document = global.document = window.document
$ = global.$ = global.jQuery = require('jquery')(window);

# Include chai
global.chai = chai = require "chai"
global.assert = assert = chai.assert
global.expect = expect = chai.expect

# Include chai-jquery (if possible)
try
  global.chaijQuery = chaijQuery = require "chai-jquery"
  chai.use chaijQuery
catch e

# Extend global object with chai.should
chai.should()

