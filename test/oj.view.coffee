# oj.view.coffee

path = require 'path'
fs = require 'fs'

fileModifiedTime = (filepath, cb) ->
  fs.stat filepath, (err, data) ->
    return cb(err, data) if err
    cb(err, data.mtime)

oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.view', ->

  it 'exists', ->
    assert oj.view != null, 'oj.view is null'
    oj.view.should.be.a 'function'
