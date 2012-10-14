# test/oj.template.coffee
#
# Test oj.template method for generating html, css, javascript

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

describe 'oj.template', ->
  beforeEach ->
    _clear $('body')

  it 'exists', ->
    expect(oj.template).to.exist
    oj.template.should.be.a 'function'

  it 'template empty list'
  it 'template empty string'
  it 'template div'
  it 'template span'
  it 'template object with .ojml'
