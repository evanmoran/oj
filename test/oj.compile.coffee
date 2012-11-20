# test/oj.compile.coffee
#
# Test oj.compile method for generating html, css, javascript

path = require 'path'
fs = require 'fs'
async = require 'async'

oj = require '../src/oj.coffee'
oj.extend this

bodyWrap = (str = '') -> "<body>#{str}</body>"
headEmpty = '<head></head>'
bodyEmpty = bodyWrap()
div1 = '<div id="1">1</div>'
div2 = '<div id="2">2</div>'
div3 = '<div id="3">3</div>'
divs123 = [div1, div2, div3]
_el = -> $('body').get(0)
_clear = ($el = $('body')) -> $el.html ''
_set = (html, $el = $('body')) -> $el.html html
_get = ($el = $('body')) -> $el.html()
_log = ($el) -> console.log _get()
_getAll = -> $('html').html()
_logAll = -> console.log _getAll()
_clearAll = -> $('html').html headEmpty + bodyEmpty

compileTest = (ojml, typesLength, html, options = {}) ->
  options = _.defaults {}, options

  r = oj.compile ojml, options
  expect(r.js).to.be.a 'function'
  expect(r.types).to.be.an 'array'
  expect(r.types.length).to.equal typesLength
  if not (options.html == false)
    expect(r.html).to.be.a 'string'
    expect(r.html).to.equal html
  else
    expect(r.html).to.not.exist

compileTestException = (ojml, exception, options = {}) ->
  expect(-> oj.compile ojml, options).to.throw exception

describe 'oj.compile', ->
  beforeEach ->
    _clear $('body')

  it 'exists', ->
    expect(oj.compile).to.exist
    oj.compile.should.be.a 'function'

  it 'div', ->
    ojml = oj.div 'test'
    compileTest ojml, 0, '<div>test</div>'

  it 'null', ->
    compileTest null, 0, ''

  it 'undefined', ->
    compileTest undefined, 0, ''

  it 'empty list', ->
    compileTestException [], 'oj.compile: tag is missing'

  it 'empty string', ->
    compileTest '', 0, ''

  it 'string', ->
    compileTest 'test', 0, 'test'

  it 'number', ->
    compileTest 42, 0, '42'

  it 'boolean', ->
    compileTest true, 0, 'true'
    compileTest false, 0, 'false'

  it 'span', ->
    ojml = oj.span 'test'
    compileTest ojml, 0, '<span>test</span>'

  it 'opened', ->
    ojml = oj.hr()
    compileTest ojml, 0, '<hr>'

  it 'closed', ->
    ojml = oj.div()
    compileTest ojml, 0, '<div></div>'

  it 'nested divs', ->
    ojml = oj.div oj.div 'test'
    compileTest ojml, 0, '<div><div>test</div></div>'

  it 'attributes empty', ->
    ojml = oj.div {}, ->
    compileTest ojml, 0, '<div></div>'

  it 'attributes class', ->
    ojml = oj.div class: 'c1', ->
    compileTest ojml, 0, '<div class="c1"></div>'

  it 'attributes class with c', ->
    ojml = oj.div c: 'c1', ->
    compileTest ojml, 0, '<div class="c1"></div>'

  it 'attributes id', ->
    ojml = oj.div id: 'id1', ->
    compileTest ojml, 0, '<div id="id1"></div>'

  it 'attributes multiple', ->
    ojml = oj.div class: 'c1', id: 'id1', ->
    compileTest ojml, 0, '<div class="c1" id="id1"></div>'

  it 'attributes style string', ->
    ojml = oj.div style: 'text-align:center; color:red', ->
    compileTest ojml, 0, '<div style="text-align:center; color:red"></div>'

  it 'attributes style object', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
    compileTest ojml, 0, '<div style="color:red;text-align:center"></div>'

  it 'attributes style object with fancy keys', ->
    ojml = oj.div style: {textAlign:'center', color: 'red'}, ->
    compileTest ojml, 0, '<div style="color:red;text-align:center"></div>'

  it 'nested', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
      oj.div 'a1', ->
        oj.div 'b1'
      oj.div 'a2'
    expected = '<div style="color:red;text-align:center"><div>a1<div>b1</div></div><div>a2</div></div>'
    compileTest ojml, 0, expected, pretty: false

  it 'nested with pretty printing', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
      oj.div 'a1', ->
        oj.div 'b1'
      oj.div 'a2'
    expected = '<div style="color:red;text-align:center">\n\t<div>\n\t\ta1\n\t\t<div>b1</div>\n\t</div>\n\t<div>a2</div>\n</div>'
    compileTest ojml, 0, expected, pretty: true
