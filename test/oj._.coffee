path = require 'path'
fs = require 'fs'

oj = require '../generated/oj.js'
Backbone = require 'backbone'
_ = oj.__

describe 'oj._', ->
  array0 = []
  array1 = [1]
  array2 = [1,2]
  array3 = [1,2,3]
  obj0 = {}
  obj1 = {one: 1}
  obj2 = {one: 1, two: 2}
  obj3 = {one: 1, two: 2, three: 3}
  objKeys3 = ['one', 'two', 'three']
  fn1 = -> 1
  fn2 = -> 2
  fn3 = -> 3
  fnI = (v) -> v
  fnPlus1 = (v) -> v + 1
  objValues3 = array3

  it 'isUndefined', ->
    (oj.isUndefined undefined).should.equal true
    (oj.isUndefined null).should.equal false
    (oj.isUndefined true).should.equal false
    (oj.isUndefined 1).should.equal false
    (oj.isUndefined "string").should.equal false
    (oj.isUndefined []).should.equal false
    (oj.isUndefined {}).should.equal false
    (oj.isUndefined ->).should.equal false

  it 'isBoolean', ->
    (oj.isBoolean undefined).should.equal false
    (oj.isBoolean null).should.equal false
    (oj.isBoolean true).should.equal true
    (oj.isBoolean false).should.equal true
    (oj.isBoolean 0).should.equal false
    (oj.isBoolean 1).should.equal false
    (oj.isBoolean "string").should.equal false

  it 'isNumber', ->
    (oj.isNumber undefined).should.equal false
    (oj.isNumber null).should.equal false
    (oj.isNumber true).should.equal false
    (oj.isNumber 1).should.equal true
    (oj.isNumber "string").should.equal false

  it 'isString', ->
    (oj.isString undefined).should.equal false
    (oj.isString null).should.equal false
    (oj.isString true).should.equal false
    (oj.isString 1).should.equal false
    (oj.isString "string").should.equal true

  it 'isDate', ->
    (oj.isDate new Date()).should.equal true
    (oj.isDate new Date("2012-2-1")).should.equal true
    (oj.isDate undefined).should.equal false
    (oj.isDate null).should.equal false
    (oj.isDate true).should.equal false
    (oj.isDate "string").should.equal false

  it 'isFunction', ->
    assert.isTrue (oj.isFunction (v)->v), 'identity function case'
    assert.isFalse (oj.isFunction []), '[] case'
    assert.isFalse (oj.isFunction {}), '{} case'
    assert.isFalse (oj.isFunction undefined), 'undefined case'
    assert.isFalse (oj.isFunction null), 'null case'
    assert.isFalse (oj.isFunction true, 'true case')
    assert.isFalse (oj.isFunction 1), '1 case'
    assert.isFalse (oj.isFunction "string"), 'string case'

  it 'isArray', ->
    assert.isTrue (oj.isArray []), '[] case'
    assert.isTrue (oj.isArray [1,2]), '[1,2] case'
    assert.isTrue (oj.isArray new Array), 'new Array case'
    assert.isFalse (oj.isArray {}), '{} case'
    assert.isFalse (oj.isArray {a:1, b:2}), '{a:1, b:2} case'
    assert.isFalse (oj.isArray undefined), 'undefined case'
    assert.isFalse (oj.isArray null), 'null case'
    assert.isFalse (oj.isArray true, 'true case')
    assert.isFalse (oj.isArray 1), '1 case'
    assert.isFalse (oj.isArray "string"), 'string case'

  it 'isObject', ->
    assert.isTrue (oj.isObject {}), '{} case'
    assert.isTrue (oj.isObject {a:1, b:2}), '{a:1, b:2} case'
    assert.isFalse (oj.isObject []), '[] case'
    assert.isFalse (oj.isObject /abc/), '/abc/ case'
    assert.isFalse (oj.isObject new Array), 'new Array case'
    assert.isFalse (oj.isObject undefined), 'undefined case'
    assert.isFalse (oj.isObject null), 'null case'
    assert.isFalse (oj.isObject true, 'true case')
    assert.isFalse (oj.isObject new Date, 'new Date case')
    assert.isFalse (oj.isObject 1), '1 case'
    assert.isFalse (oj.isObject "string"), 'string case'


  it 'isEvent', ->
    class UserModel extends Backbone.Model
    user = new UserModel name:'Evan'
    expect(oj.isEvent(user)).to.equal true
    expect(oj.typeOf(user)).to.equal 'object'

  it 'isOJML'

  it 'isElement'

  it 'isjQuery'
