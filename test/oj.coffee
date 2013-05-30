path = require 'path'
fs = require 'fs'
async = require 'async'

fileModifiedTime = (filepath, cb) ->
  fs.stat filepath, (err, data) ->
    return cb(err, data) if err
    cb(err, data.mtime)

oj = require '../lib/oj.js'

describe 'oj', ->
  dir = process.cwd()
  ojCoffeeFile = path.join dir, 'src/oj.litcoffee'
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

  it 'isOJ', ->
    Empty = oj.type 'Empty', {}
    empty = new Empty()
    empty2 = Empty()
    assert.equal (oj.isOJ empty), true, 'new case}'
    assert.equal (oj.isOJ empty2), true, 'no new case}'

  it 'typeOf', ->
    assert.equal (oj.typeOf {}), 'object', '{} case}'
    assert.equal (oj.typeOf {a:1}), 'object', '{a:1} case}'

    Empty = oj.type 'Empty', {}
    empty = new Empty()
    empty2 = Empty()
    assert.equal (oj.typeOf Empty), 'function', 'oj type case'
    assert.equal (oj.typeOf empty), 'Empty', 'oj instance case'
    assert.equal (oj.typeOf empty2), 'Empty', 'oj instance case (no new)'

    assert.equal (oj.typeOf new Array), 'array', 'new Array case'
    assert.equal (oj.typeOf null), 'null', 'null case'
    assert.equal (oj.typeOf undefined), 'undefined', 'undefined case'
    assert.equal (oj.typeOf 0), 'number', '0 case'
    assert.equal (oj.typeOf 1), 'number', '1 case'
    assert.equal (oj.typeOf 3.14), 'number', '3.14 case'
    assert.equal (oj.typeOf NaN), 'number', 'NaN case'
    assert.equal (oj.typeOf ''), 'string', 'empty string case'
    assert.equal (oj.typeOf 'string'), 'string', 'string case'
    assert.equal (oj.typeOf new Date), 'date', 'new Date case'
    assert.equal (oj.typeOf /abc/), 'regexp', '/abc/ case'

    # TODO: Add these cases
    # assert.equal (Document.createElement('div')), 'dom', 'dom case'
    # assert.equal (oj.typeOf $()), 'jquery', 'jquery case'
    # assert.equal (oj.typeOf new Backbone.Model.extend()), 'backbone', 'backbone case'


























