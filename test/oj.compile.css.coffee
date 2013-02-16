# test/oj.compile.coffee
#
# Test oj.compile method for generating html, css, javascript

path = require 'path'
fs = require 'fs'
async = require 'async'

oj = require '../src/oj.coffee'
oj.extend this

cssTest = (ojml, css, options) ->
  options = _.defaults {}, options,
    css:true
    debug:false
  r = oj.compile options, ojml
  expect(r.js).to.be.a 'function'
  if not (options.css == false)
    expect(r.css).to.be.a 'string'
    expect(r.css).to.equal css
  else
    expect(r.css).to.not.exist

cssTestException = (ojml, exception, options = {}) ->
  expect(-> oj.compile options, ojml).to.throw exception

_clear = ($el = $('body')) -> $el.html ''

describe 'oj.compile.css', ->
  beforeEach ->
    _clear $('body')

  it 'exists', ->
    expect(oj.compile).to.exist
    oj.compile.should.be.a 'function'

  it 'span without css', ->
    ojml = oj.span 'test'
    cssTest ojml, ''

  it 'divs without css', ->
    ojml = oj.div ->
      oj.div 'test'
    cssTest ojml, ''

  it 'one rule', ->
    ojml = oj.css
      body:
        color: 'red'
    cssTest ojml, 'body{color:red}'

  it 'two rules', ->
    ojml = oj.css
      body:
        color: 'red'
      '.selector':
        border: '1px solid black'

    cssTest ojml, 'body{color:red}.selector{border:1px solid black}'

  it 'one rule debug', ->
    ojml = oj.css
      body:
        color: 'red'
    cssTest ojml, 'body {\n\tcolor:red;\n}', debug:true

  # TODO: This can only work if css minifier is really smart. Not sure if it supports this..
  it 'merged rules'
    # ojml = oj.css
    #   '.c1':
    #     color: 'red'
    #   '.c2':
    #     color: 'red'
    # cssTest ojml, '.c1,.c2{color:red}'

  it 'merged rules debug', ->
    ojml = oj.css
      '.c1':
        color: 'red'
      '.c2':
        color: 'red'
    cssTest ojml, '.c1 {\n\tcolor:red;\n}.c2 {\n\tcolor:red;\n}',debug:true

