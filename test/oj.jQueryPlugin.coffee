# oj.jQueryPlugin.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.jQueryPlugin', ->
  it 'plugins exists'

###, ->
    expect($('body').oj).to.be.a 'function'
    expect($('body').ojAfter).to.be.a 'function'
    expect($('body').ojBefore).to.be.a 'function'
    expect($('body').ojAppend).to.be.a 'function'
    expect($('body').ojPrepend).to.be.a 'function'
    expect($('body').ojReplace)
###