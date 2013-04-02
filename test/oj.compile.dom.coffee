# test/oj.compile.dom.coffee
#
# Test oj.compile method for generating dom structure with bound events

path = require 'path'
fs = require 'fs'
async = require 'async'

oj = require '../src/oj.coffee'
oj.extend this

compileDOM = (ojml, tag, childrenCount, html, options) ->
  options = _.defaults {}, options,
    html:true
    css:false
    dom:true
    debug:false
  r = oj.compile options, ojml
  if options.dom
    if _.isArray r.dom
      for d,ix in r.dom
        expect(oj.typeOf(d)).to.equal 'element'
        expect(d.tagName).to.equal tag[ix].toUpperCase()
        expect(d.outerHTML).to.equal html[ix]
    else
      expect(oj.typeOf(r.dom)).to.equal 'element'
      expect(r.dom.tagName).to.equal tag.toUpperCase()
      expect(r.dom.outerHTML).to.equal html
  else
    expect(r.dom).to.not.exist

compileDOMText = (ojml, text, options) ->
  options = _.defaults {}, options,
    html:false
    css:false
    dom:true
    debug:false
  r = oj.compile options, ojml
  if options.dom
    if r.dom?
      expect(oj.typeOf(r.dom)).to.equal 'text'
      expect(r.dom.data).to.equal text
    else
      expect(text).to.not.exist
  else
    expect(r.dom).to.not.exist

compileDOMException = (ojml, exception, options = {}) ->
  expect(-> oj.compile options, ojml).to.throw exception

_clear = ($el = $('body')) -> $el.html ''

describe 'oj.compile.dom', ->
  beforeEach ->
    _clear $('body')

  it 'exists', ->
    expect(oj.compile).to.exist
    oj.compile.should.be.a 'function'

  it 'div string', ->
    ojml = oj.div 'test'
    compileDOM ojml, 'div', 0, '<div>test</div>'

  it 'div number', ->
    ojml = oj.div 42
    compileDOM ojml, 'div', 0, '<div>42</div>'

  it 'div boolean', ->
    ojml = oj.div false
    compileDOM ojml, 'div', 0, '<div>false</div>'
    ojml = oj.div true
    compileDOM ojml, 'div', 0, '<div>true</div>'

  it 'values', ->
    compileDOMText '', ''
    compileDOMText 'test', 'test'
    compileDOMText 42, '42'
    compileDOMText true, 'true'
    compileDOMText false, 'false'
    compileDOMText [], null
    compileDOMText null, null
    compileDOMText undefined, undefined

    r = oj.compile dom:true,html:false, ->
    expect(r.dom).to.equal null

  it 'function returning value', ->
    compileDOMText (-> true), 'true'
    compileDOMText (-> false), 'false'
    compileDOMText (-> 42), '42'
    compileDOMText (-> 'test'), 'test'
    compileDOMText (-> undefined), undefined
    compileDOMText (-> null), null

  it 'span', ->
    ojml = oj.span 'test'
    compileDOM ojml, 'span', 0, '<span>test</span>'

  it 'opened', ->
    ojml = oj.hr()
    compileDOM ojml, 'hr', 0, '<hr />'

  it 'closed', ->
    ojml = oj.div()
    compileDOM ojml, 'div', 0, '<div></div>'

  it 'nested divs', ->
    ojml = oj.div oj.div 'test'
    compileDOM ojml, 'div', 1, '<div><div>test</div></div>'

  it 'attributes empty', ->
    ojml = oj.div {}, ->
    compileDOM ojml, 'div', 0, '<div></div>'

  it 'attributes class', ->
    ojml = oj.div class: 'c1', ->
    compileDOM ojml, 'div', 0, '<div class="c1"></div>'

  it 'attributes class with c', ->
    ojml = oj.div c: 'c1', ->
    compileDOM ojml, 'div', 0, '<div class="c1"></div>'

  it 'attributes id', ->
    ojml = oj.div id: 'id1', ->
    compileDOM ojml, 'div', 0, '<div id="id1"></div>'

  it 'attributes multiple', ->
    ojml = oj.div class: 'c1', id: 'id1', ->
    compileDOM ojml, 'div', 0, '<div class="c1" id="id1"></div>'

  it 'attributes style string', ->
    ojml = oj.div style: 'text-align:center; color:red', ->
    compileDOM ojml, 'div', 0, '<div style="text-align: center; color: red;"></div>'

  it 'attributes style object', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
    compileDOM ojml, 'div', 0, '<div style="color: red; text-align: center;"></div>'

  it 'attributes style object with fancy keys', ->
    ojml = oj.div style: {textAlign:'center', color: 'red'}, ->
    compileDOM ojml, 'div', 0, '<div style="color: red; text-align: center;"></div>'

  it 'simple nested', ->
    ojml = oj.div ->
      oj.span 'a1'
    expected = '<div><span>a1</span></div>'
    compileDOM ojml, 'div', 0, expected, debug: false

  it 'nested', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
      oj.div 'a1', ->
        oj.div 'b1'
      oj.div 'a2'
    expected = '<div style="color: red; text-align: center;"><div>a1<div>b1</div></div><div>a2</div></div>'
    compileDOM ojml, 'div', 2, expected, debug: false

  # Debug should have no effect on dom creation
  it 'nested with debug printing', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
      oj.div 'a1', ->
        oj.div 'b1'
      oj.div 'a2'
    expected = '<div style="color: red; text-align: center;"><div>a1<div>b1</div></div><div>a2</div></div>'
    compileDOM ojml, 'div', 2, expected, debug: true

  it '<html><body>', ->
    ojml = oj.html ->
      oj.body ->
        oj.div 'a1'
    expected = '<html><body><div>a1</div></body></html>'
    compileDOM ojml, 'html', 1, expected, debug: false

  it '<html><body> with debug printing', ->
    ojml = oj.html ->
      oj.body ->
        oj.div 'a1'
    expected = '<html><body><div>a1</div></body></html>'
    compileDOM ojml, 'html', 1, expected, debug: true

  it '<html><head><body>', ->
      ojml = oj.html ->
        oj.head ->
          oj.script type: 'text/javascript', src: 'script.js'
        oj.body ->
          oj.div 'a1'
          # css should be ignored in structure
          oj.css '.selector':color:'red'
      expected = '<html><head><script src="script.js" type="text/javascript"></script></head><body><div>a1</div></body></html>'
      # compileDOM ojml, 'html', 1, expected, debug: false
      r = oj.compile debug:false,html:false,dom:true, ojml
      expect(r.dom.outerHTML).to.equal expected

  it '<html><head><body> with ignore', ->
    ojml = oj.html ->
      oj.head ->
        oj.script type: 'text/javascript', src: 'script.js'
      oj.body ->
        oj.div 'a1'
    expected = '<body><div>a1</div></body>'
    compileDOM ojml, 'body', 0, expected, ignore: {html:1, doctype:1, head:1, link:1, script:1}



