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
    (_.isUndefined undefined).should.equal true
    (_.isUndefined null).should.equal false
    (_.isUndefined true).should.equal false
    (_.isUndefined 1).should.equal false
    (_.isUndefined "string").should.equal false
    (_.isUndefined []).should.equal false
    (_.isUndefined {}).should.equal false
    (_.isUndefined ->).should.equal false

  it 'isBoolean', ->
    (_.isBoolean undefined).should.equal false
    (_.isBoolean null).should.equal false
    (_.isBoolean true).should.equal true
    (_.isBoolean false).should.equal true
    (_.isBoolean 0).should.equal false
    (_.isBoolean 1).should.equal false
    (_.isBoolean "string").should.equal false

  it 'isNumber', ->
    (_.isNumber undefined).should.equal false
    (_.isNumber null).should.equal false
    (_.isNumber true).should.equal false
    (_.isNumber 1).should.equal true
    (_.isNumber "string").should.equal false

  it 'isString', ->
    (_.isString undefined).should.equal false
    (_.isString null).should.equal false
    (_.isString true).should.equal false
    (_.isString 1).should.equal false
    (_.isString "string").should.equal true


  it 'isDate', ->
    (_.isDate new Date()).should.equal true
    (_.isDate new Date("2012-2-1")).should.equal true
    (_.isDate undefined).should.equal false
    (_.isDate null).should.equal false
    (_.isDate true).should.equal false
    (_.isDate "string").should.equal false

  it 'isFunction', ->
    assert.isTrue (_.isFunction (v)->v), 'identity function case'
    assert.isFalse (_.isFunction []), '[] case'
    assert.isFalse (_.isFunction {}), '{} case'
    assert.isFalse (_.isFunction undefined), 'undefined case'
    assert.isFalse (_.isFunction null), 'null case'
    assert.isFalse (_.isFunction true, 'true case')
    assert.isFalse (_.isFunction 1), '1 case'
    assert.isFalse (_.isFunction "string"), 'string case'

  it 'isArray', ->
    assert.isTrue (_.isArray []), '[] case'
    assert.isTrue (_.isArray [1,2]), '[1,2] case'
    assert.isTrue (_.isArray new Array), 'new Array case'
    assert.isFalse (_.isArray {}), '{} case'
    assert.isFalse (_.isArray {a:1, b:2}), '{a:1, b:2} case'
    assert.isFalse (_.isArray undefined), 'undefined case'
    assert.isFalse (_.isArray null), 'null case'
    assert.isFalse (_.isArray true, 'true case')
    assert.isFalse (_.isArray 1), '1 case'
    assert.isFalse (_.isArray "string"), 'string case'

  it 'typeOf', ->
    assert.equal (_.typeOf {}), 'object', '{} case}'
    assert.equal (_.typeOf {a:1}), 'object', '{a:1} case}'

    Empty = oj.type 'Empty', {}
    empty = Empty()
    assert.equal (_.typeOf Empty), 'function', 'oj type case'
    assert.equal (_.typeOf empty), 'Empty', 'oj instance case'

    assert.equal (_.typeOf new Array), 'array', 'new Array case'
    assert.equal (_.typeOf null), 'null', 'null case'
    assert.equal (_.typeOf undefined), 'undefined', 'undefined case'
    assert.equal (_.typeOf 0), 'number', '0 case'
    assert.equal (_.typeOf 1), 'number', '1 case'
    assert.equal (_.typeOf 3.14), 'number', '3.14 case'
    assert.equal (_.typeOf NaN), 'number', 'NaN case'
    assert.equal (_.typeOf ''), 'string', 'empty string case'
    assert.equal (_.typeOf 'string'), 'string', 'string case'
    assert.equal (_.typeOf new Date), 'date', 'new Date case'
    assert.equal (_.typeOf /abc/), 'regexp', '/abc/ case'

    # TODO: Add these cases
    # assert.equal (Document.createElement('div')), 'dom', 'dom case'
    # assert.equal (_.typeOf $()), 'jquery', 'jquery case'
    # assert.equal (_.typeOf new Backbone.Model.extend()), 'backbone', 'backbone case'

  it 'isObject', ->
    assert.isTrue (_.isObject {}), '{} case'
    assert.isTrue (_.isObject {a:1, b:2}), '{a:1, b:2} case'
    assert.isFalse (_.isObject []), '[] case'
    assert.isFalse (_.isObject /abc/), '/abc/ case'
    assert.isFalse (_.isObject new Array), 'new Array case'
    assert.isFalse (_.isObject undefined), 'undefined case'
    assert.isFalse (_.isObject null), 'null case'
    assert.isFalse (_.isObject true, 'true case')
    assert.isFalse (_.isObject new Date, 'new Date case')
    assert.isFalse (_.isObject 1), '1 case'
    assert.isFalse (_.isObject "string"), 'string case'

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

  it 'isOJ', ->


  it 'isOJML'
  it 'isElement'
  it 'isjQuery'
  it 'isBackbone'

  # Test _.dom helpers
  # ----------------------------------------------------------------------------------------
  bodyWrap = (str = '') -> "<body>#{str}</body>"
  headEmpty = '<head></head>'
  bodyEmpty = bodyWrap()
  div1 = '<div id="1">1</div>'
  div2 = '<div id="2">2</div>'
  div3 = '<div id="3">3</div>'
  divs123 = [div1, div2, div3]

  # Test _.dom methods
  # ----------------------------------------------------------------------------------------
  _el = -> $('body').get(0)
  _clear = ($el = $('body')) -> $el.html ''
  _set = (html, $el = $('body')) -> $el.html html
  _get = ($el = $('body')) -> $el.html()
  _log = ($el) -> console.log _get()
  _getAll = -> $('html').html()
  _logAll = -> console.log _getAll()
  _clearAll = -> $('html').html headEmpty + bodyEmpty

  # Call method on (el,html) for all html in listHtml
  _domEach = (method, el, listHtml) ->
    for html in listHtml
      method _el(), html
    _getAll()

  # Clear html before every call
  beforeEach ->
    _clearAll()

  it 'domReplaceHtml', ->
    result = _domEach _.domReplaceHtml, _el(), divs123
    expect(result).to.equal headEmpty + bodyWrap(div3)

  it 'domAppendHtml', ->
    result = _domEach _.domAppendHtml, _el(), divs123
    expect(result).to.equal headEmpty + bodyWrap(div1 + div2 + div3)

  it 'domPrependHtml', ->
    result = _domEach _.domPrependHtml, _el(), divs123
    expect(result).to.equal headEmpty + bodyWrap(div3 + div2 + div1)

  it 'domInsertHtmlBefore', ->
    result = _domEach _.domInsertHtmlBefore, _el(), divs123
    expect(result).to.equal headEmpty + div1 + div2 + div3 + bodyEmpty

  it 'domInsertHtmlAfter', ->
    result = _domEach _.domInsertHtmlAfter, _el(), divs123
    expect(result).to.equal headEmpty + bodyEmpty + div3 + div2 + div1

  it 'domInsertElementAfter', ->
    result = _domEach _.domAppendHtml, _el(), divs123
    el1 = $('div#1').get(0)
    el2 = $('div#2').get(0)
    el3 = $('div#3').get(0)
    expect(result).to.equal headEmpty + bodyWrap(div1 + div2 + div3)
    # Move el3 to after el1
    _.domInsertElementAfter el1, el3
    expect(_getAll()).to.equal headEmpty + bodyWrap(div1 + div3 + div2)

