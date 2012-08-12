#──────────────────────────────────────────────────────
# Globals for mocha testing
#──────────────────────────────────────────────────────

# Include common testing modules
_ = global._ = require 'underscore'
$ = global.$ = require 'jquery'

# supertest = global.supertest = require 'supertest'

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

