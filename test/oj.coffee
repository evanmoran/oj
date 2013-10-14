path = require 'path'
fs = require 'fs'
async = require 'async'

fileModifiedTime = (filepath, cb) ->
  fs.stat filepath, (err, data) ->
    return cb(err, data) if err
    cb(err, data.mtime)

oj = require '../src/oj.js'

describe 'oj', ->
  dir = process.cwd()

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

  it 'oj.extendInto', ->
    oj2 = {}
    oj.extendInto oj2
    assert.isUndefined oj2.extendInto, 'extend should not extend itself'
    assert.isUndefined oj2._, 'extend should not extend helper methods'
    assert.isFunction oj2.tag, 'extend should extend methods (tag)'
    assert.isFunction oj2.div, 'extend should extend methods (div)'
    assert.isFunction oj2.table, 'extend should extend methods (table)'
    # assert.isObject oj2.Table, 'extend should extend objects (Table)'
    # assert.isObject oj2.Image, 'extend should extend objects (Image)'
    # assert.isObject oj2.CheckBox, 'extend should extend objects (CheckBox)'

  it 'isOJ', ->
    Empty = oj.createType 'Empty', {}
    empty = new Empty()
    empty2 = Empty()
    assert.equal (oj.isOJ empty), true, 'new case}'
    assert.equal (oj.isOJ empty2), true, 'no new case}'

  it 'isPlainObject', ->

    Empty = oj.createType 'Empty', {}
    empty = new Empty()
    empty2 = Empty()

    assert.equal (oj.isPlainObject {}), true, 'empty object case'
    assert.equal (oj.isPlainObject {a:1}), true, 'object case'

    # OJ types and instances
    assert.equal (oj.isPlainObject Empty), false, 'oj type case'
    assert.equal (oj.isPlainObject empty), false, 'oj instance case'
    assert.equal (oj.isPlainObject empty2), false, 'oj instance case (no new)'

    # Plain types
    assert.equal (oj.isPlainObject new Array), false, 'new Array case'
    assert.equal (oj.isPlainObject null), false, 'null case'
    assert.equal (oj.isPlainObject undefined), false, 'undefined case'
    assert.equal (oj.isPlainObject 0), false, '0 case'
    assert.equal (oj.isPlainObject 3.14), false, '3.14 case'
    assert.equal (oj.isPlainObject NaN), false, 'NaN case'
    assert.equal (oj.isPlainObject ''), false, 'empty string case'
    assert.equal (oj.isPlainObject 'string'), false, 'string case'
    assert.equal (oj.isPlainObject new Date), false, 'new Date case'
    assert.equal (oj.isPlainObject /abc/), false, '/abc/ case'


























