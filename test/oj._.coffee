path = require 'path'
fs = require 'fs'
async = require 'async'

oj = require '../src/oj.coffee'

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
    oj._.each array3, ((v,k,o) ->
      assert.equal this, 'this', 'this is incorrect'
      assert.equal o, array3, "obj is incorrect"
      assert.equal k, i, "key is incorrect"
      assert.equal v, array3[i], "value is incorrect"
      i++
      done() if i == array3.length),
      "this"

  it 'each Object', (done) ->
    i = 0
    oj._.each obj3, ((v,k,o) ->
      assert.equal this, 'this', 'this is incorrect'
      assert.equal o, obj3, "obj is incorrect"
      assert.equal k, objKeys3[i], "key is incorrect"
      assert.equal v, objValues3[i], "value is incorrect"
      i++
      done() if i == array3.length), "this"

  it 'map', ->
    # Values
    (oj._.map 1, fnPlus1).should.deep.equal 2
    (oj._.map fn2, fnPlus1).should.deep.equal fn2

    # Array
    (oj._.map array3, fnPlus1).should.deep.equal [2,3,4]

    # Object
    (oj._.map obj3, fnPlus1).should.deep.equal {one: 2, two: 3, three:4}

    # Null in the middle
    (oj._.map [null,2,3], (v) -> if v then v+1 else null ).should.deep.equal [null,3,4]

  it 'map recursive', ->
    # Object
    (oj._.map {a:1,b:{c:2}}, fnPlus1, recurse: true).should.deep.equal {a:2,b:{c:3}}

    # Array
    (oj._.map [1,2,[3, [4]]], fnPlus1, recurse: true).should.deep.equal [2,3,[4,[5]]]

    # Array
    (oj._.map [1,fn2,{a:3, b:[4]}], fnPlus1, recurse: true).should.deep.equal [2,fn2,{a:4, b:[5]}]

  it 'map evaluate', ->
    # Function
    (oj._.map (->1), fnPlus1, recurse: true, evaluate: true).should.deep.equal 2

    # Function
    (oj._.map (->[]), fnPlus1, recurse: true, evaluate: true).should.deep.equal []

    # Empty object
    (oj._.map (->{}), fnPlus1, recurse: true, evaluate: true).should.deep.equal {}

    # Empty object
    (oj._.map (->{a:1}), fnPlus1, recurse: true, evaluate: true).should.deep.equal {a:2}

    # Array, Object
    (oj._.map [1,(->2),{a:3, b:[4]}], fnPlus1, recurse: true, evaluate: true).should.deep.equal [2,3,{a:4, b:[5]}]

    # Super complex nested
    (oj._.map (->[1,(->2),{a:3, b:(->[(->4)])}]), fnPlus1, recurse: true, evaluate: true).should.deep.equal [2,3,{a:4, b:[5]}]

  it 'keys', ->
    (oj._.keys {}).should.deep.equal []
    (oj._.keys obj3).should.deep.equal objKeys3

  it 'values', ->
    (oj._.values {}).should.deep.equal []
    (oj._.values obj3).should.deep.equal objValues3

  it 'flatten'
  it 'bind'
  it 'reduce'

    # expect(oj._.values 1).should.throw 'Invalid object'

  it 'isUndefined', ->
    (oj._.isUndefined undefined).should.equal true
    (oj._.isUndefined null).should.equal false
    (oj._.isUndefined true).should.equal false
    (oj._.isUndefined 1).should.equal false
    (oj._.isUndefined "string").should.equal false
    (oj._.isUndefined []).should.equal false
    (oj._.isUndefined {}).should.equal false
    (oj._.isUndefined ->).should.equal false

  it 'isBoolean', ->
    (oj._.isBoolean undefined).should.equal false
    (oj._.isBoolean null).should.equal false
    (oj._.isBoolean true).should.equal true
    (oj._.isBoolean false).should.equal true
    (oj._.isBoolean 0).should.equal false
    (oj._.isBoolean 1).should.equal false
    (oj._.isBoolean "string").should.equal false

  it 'isNumber', ->
    (oj._.isNumber undefined).should.equal false
    (oj._.isNumber null).should.equal false
    (oj._.isNumber true).should.equal false
    (oj._.isNumber 1).should.equal true
    (oj._.isNumber "string").should.equal false

  it 'isString', ->
    (oj._.isString undefined).should.equal false
    (oj._.isString null).should.equal false
    (oj._.isString true).should.equal false
    (oj._.isString 1).should.equal false
    (oj._.isString "string").should.equal true


  it 'isDate', ->
    (oj._.isDate new Date()).should.equal true
    (oj._.isDate new Date("2012-2-1")).should.equal true
    (oj._.isDate undefined).should.equal false
    (oj._.isDate null).should.equal false
    (oj._.isDate true).should.equal false
    (oj._.isDate "string").should.equal false

  it 'isFunction', ->
    assert.isTrue (oj._.isFunction (v)->v), 'identity function case'
    assert.isFalse (oj._.isFunction []), '[] case'
    assert.isFalse (oj._.isFunction {}), '{} case'
    assert.isFalse (oj._.isFunction undefined), 'undefined case'
    assert.isFalse (oj._.isFunction null), 'null case'
    assert.isFalse (oj._.isFunction true, 'true case')
    assert.isFalse (oj._.isFunction 1), '1 case'
    assert.isFalse (oj._.isFunction "string"), 'string case'

  it 'isArray', ->
    assert.isTrue (oj._.isArray []), '[] case'
    assert.isTrue (oj._.isArray [1,2]), '[1,2] case'
    assert.isTrue (oj._.isArray new Array), 'new Array case'
    assert.isFalse (oj._.isArray {}), '{} case'
    assert.isFalse (oj._.isArray {a:1, b:2}), '{a:1, b:2} case'
    assert.isFalse (oj._.isArray undefined), 'undefined case'
    assert.isFalse (oj._.isArray null), 'null case'
    assert.isFalse (oj._.isArray true, 'true case')
    assert.isFalse (oj._.isArray 1), '1 case'
    assert.isFalse (oj._.isArray "string"), 'string case'

  it 'typeOf', ->
    assert.equal (oj._.typeOf {}), 'object', '{} case}'
    assert.equal (oj._.typeOf {a:1}), 'object', '{a:1} case}'
    assert.equal (oj._.typeOf {oj: 'div'}), 'ojml', '{oj: "div"} case'
    assert.equal (oj._.typeOf {ojtype: 'Table'}), 'Table', 'ojtype case'
    assert.equal (oj._.typeOf new Array), 'array', 'new Array case'
    assert.equal (oj._.typeOf null), 'null', 'null case'
    assert.equal (oj._.typeOf undefined), 'undefined', 'undefined case'
    assert.equal (oj._.typeOf 0), 'number', '0 case'
    assert.equal (oj._.typeOf 1), 'number', '1 case'
    assert.equal (oj._.typeOf 3.14), 'number', '3.14 case'
    assert.equal (oj._.typeOf NaN), 'number', 'NaN case'
    assert.equal (oj._.typeOf ''), 'string', 'empty string case'
    assert.equal (oj._.typeOf 'string'), 'string', 'string case'
    assert.equal (oj._.typeOf new Date), 'date', 'new Date case'
    assert.equal (oj._.typeOf /abc/), 'regexp', '/abc/ case'
    # assert.equal (oj._.typeOf $()), 'jquery', 'jquery case'
    # assert.equal (oj._.typeOf new Backbone.Model.extend()), 'backbone', 'backbone case'

  it 'isObject', ->
    assert.isTrue (oj._.isObject {}), '{} case'
    assert.isTrue (oj._.isObject {a:1, b:2}), '{a:1, b:2} case'
    assert.isFalse (oj._.isObject []), '[] case'
    assert.isFalse (oj._.isObject /abc/), '/abc/ case'
    assert.isFalse (oj._.isObject new Array), 'new Array case'
    assert.isFalse (oj._.isObject undefined), 'undefined case'
    assert.isFalse (oj._.isObject null), 'null case'
    assert.isFalse (oj._.isObject true, 'true case')
    assert.isFalse (oj._.isObject new Date, 'new Date case')
    assert.isFalse (oj._.isObject 1), '1 case'
    assert.isFalse (oj._.isObject "string"), 'string case'

  it 'has', ->
    (oj._.has obj3, 'zero').should.equal false
    (oj._.has obj3, 1).should.equal false
    (oj._.has obj3, null).should.equal false
    (oj._.has obj3, 'one').should.equal true
    (oj._.has obj3, 'two').should.equal true
    (oj._.has obj3, 'three').should.equal true

  it 'isOJ'
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
    result = _domEach oj._.domReplaceHtml, _el(), divs123
    expect(result).to.equal headEmpty + bodyWrap(div3)

  it 'domAppendHtml', ->
    result = _domEach oj._.domAppendHtml, _el(), divs123
    expect(result).to.equal headEmpty + bodyWrap(div1 + div2 + div3)

  it 'domPrependHtml', ->
    result = _domEach oj._.domPrependHtml, _el(), divs123
    expect(result).to.equal headEmpty + bodyWrap(div3 + div2 + div1)

  it 'domInsertHtmlBefore', ->
    result = _domEach oj._.domInsertHtmlBefore, _el(), divs123
    expect(result).to.equal headEmpty + div1 + div2 + div3 + bodyEmpty

  it 'domInsertHtmlAfter', ->
    result = _domEach oj._.domInsertHtmlAfter, _el(), divs123
    expect(result).to.equal headEmpty + bodyEmpty + div3 + div2 + div1

  it 'domInsertElementAfter', ->
    result = _domEach oj._.domAppendHtml, _el(), divs123
    el1 = $('div#1').get(0)
    el2 = $('div#2').get(0)
    el3 = $('div#3').get(0)
    expect(result).to.equal headEmpty + bodyWrap(div1 + div2 + div3)
    # Move el3 to after el1
    oj._.domInsertElementAfter el1, el3
    expect(_getAll()).to.equal headEmpty + bodyWrap(div1 + div3 + div2)

