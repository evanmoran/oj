path = require 'path'
fs = require 'fs'

oj = require '../src/oj.coffee'
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

  it 'each Array', (done) ->
    i = 0
    _.each array3, ((v,k,o) ->
      assert.equal this, 'this', 'this is incorrect'
      assert.equal o, array3, "obj is incorrect"
      assert.equal k, i, "key is incorrect"
      assert.equal v, array3[i], "value is incorrect"
      i++
      done() if i == array3.length),
      "this"

  it 'each Object', (done) ->
    i = 0
    _.each obj3, ((v,k,o) ->
      assert.equal this, 'this', 'this is incorrect'
      assert.equal o, obj3, "obj is incorrect"
      assert.equal k, objKeys3[i], "key is incorrect"
      assert.equal v, objValues3[i], "value is incorrect"
      i++
      done() if i == array3.length), "this"

  it 'map', ->
    # Values
    (_.map 1, fnPlus1).should.deep.equal 2
    (_.map fn2, fnPlus1).should.deep.equal fn2

    # Array
    (_.map array3, fnPlus1).should.deep.equal [2,3,4]

    # Object
    (_.map obj3, fnPlus1).should.deep.equal {one: 2, two: 3, three:4}

    # Null in the middle
    (_.map [null,2,3], (v) -> if v then v+1 else null ).should.deep.equal [null,3,4]

  it 'map recursive', ->
    # Object
    (_.map {a:1,b:{c:2}}, fnPlus1, recurse: true).should.deep.equal {a:2,b:{c:3}}

    # Array
    (_.map [1,2,[3, [4]]], fnPlus1, recurse: true).should.deep.equal [2,3,[4,[5]]]

    # Array
    (_.map [1,fn2,{a:3, b:[4]}], fnPlus1, recurse: true).should.deep.equal [2,fn2,{a:4, b:[5]}]

  it 'map evaluate', ->
    # Function
    (_.map (->1), fnPlus1, recurse: true, evaluate: true).should.deep.equal 2

    # Function
    (_.map (->[]), fnPlus1, recurse: true, evaluate: true).should.deep.equal []

    # Empty object
    (_.map (->{}), fnPlus1, recurse: true, evaluate: true).should.deep.equal {}

    # Empty object
    (_.map (->{a:1}), fnPlus1, recurse: true, evaluate: true).should.deep.equal {a:2}

    # Array, Object
    (_.map [1,(->2),{a:3, b:[4]}], fnPlus1, recurse: true, evaluate: true).should.deep.equal [2,3,{a:4, b:[5]}]

    # Super complex nested
    (_.map (->[1,(->2),{a:3, b:(->[(->4)])}]), fnPlus1, recurse: true, evaluate: true).should.deep.equal [2,3,{a:4, b:[5]}]

  it 'keys', ->
    (_.keys {}).should.deep.equal []
    (_.keys obj3).should.deep.equal objKeys3

  it 'values', ->
    (_.values {}).should.deep.equal []
    (_.values obj3).should.deep.equal objValues3

  it 'flatten'
  it 'bind'
  it 'reduce'

    # expect(_.values 1).should.throw 'Invalid object'

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

  it 'has', ->
    (_.has obj3, 'zero').should.equal false
    (_.has obj3, 1).should.equal false
    (_.has obj3, null).should.equal false
    (_.has obj3, 'one').should.equal true
    (_.has obj3, 'two').should.equal true
    (_.has obj3, 'three').should.equal true

  it 'uniqueSort', ->
    (_.uniqueSort []).should.deep.equal []
    (_.uniqueSort [1]).should.deep.equal [1]
    (_.uniqueSort [1,2]).should.deep.equal [1,2]
    (_.uniqueSort [2,1]).should.deep.equal [1,2]
    (_.uniqueSort [2,1,2]).should.deep.equal [1,2]
    (_.uniqueSort [2,1,2,1]).should.deep.equal [1,2]
    (_.uniqueSort [1,1,1,1]).should.deep.equal [1]

  it 'isOJML'
  it 'isElement'
  it 'isjQuery'
  it 'isBackbone'


