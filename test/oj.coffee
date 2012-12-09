path = require 'path'
fs = require 'fs'
async = require 'async'

fileModifiedTime = (filepath, cb) ->
  fs.stat filepath, (err, data) ->
    return cb(err, data) if err
    cb(err, data.mtime)

oj = require '../src/oj.coffee'

describe 'oj', ->
  dir = process.cwd()
  ojCoffeeFile = path.join dir, 'src/oj.coffee'
  ojJSFile = path.join dir, 'lib/oj.js'

  it 'should be up-to-date with the .coffee file (run \'cake build\')', (done) ->
    async.parallel
      coffee: ((cb) -> fileModifiedTime ojCoffeeFile, cb),
      js: ((cb)-> fileModifiedTime ojJSFile, cb)
      , (err, times) ->
        throw err if err
        assert times.coffee.getTime() <= times.js.getTime(), 'coffee script file is out of date'
        done()

  it 'should have the same version as package.json', (done) ->
    assert oj.version, 'oj.version does not exist'

    # Read package.json
    fs.readFile path.join(dir, 'package.json'), 'utf8', (err, data) ->
      throw err if err
      json = JSON.parse(data)
      assert json.version, 'package.json does not have a version (or couldn\'t be parsed)'
      oj.version.should.equal json.version
      done()

  it 'should be an function ', ->
    oj.should.be.an 'function'

  it 'should have a version equal to the package.json', ->
    expect(oj.version).to.be.a 'string'

  it 'oj.extend', ->
    oj2 = {}
    oj.extend oj2
    assert.isUndefined oj2.extend, 'extend should not extend itself'
    assert.isUndefined oj2._, 'extend should not extend helper methods'
    assert.isFunction oj2.tag, 'extend should extend methods (tag)'
    assert.isFunction oj2.div, 'extend should extend methods (div)'
    assert.isFunction oj2.table, 'extend should extend methods (table)'
    # assert.isObject oj2.Table, 'extend should extend objects (Table)'
    # assert.isObject oj2.Image, 'extend should extend objects (Image)'
    # assert.isObject oj2.CheckBox, 'extend should extend objects (CheckBox)'

























