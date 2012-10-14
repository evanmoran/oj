#──────────────────────────────────────────────────────
# Globals for mocha testing
#──────────────────────────────────────────────────────

# Include common testing modules
_ = global._ = require 'underscore'
jsdom = global.jsdom = (require 'jsdom').jsdom
document = global.document = jsdom "<html><head></head><body></body></html>"
window = global.window = document.createWindow()
$ = global.$ = global.jQuery = (require 'jquery').create(window)

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

