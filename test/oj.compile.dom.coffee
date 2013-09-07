# test/oj.compile.dom.coffee
#
# Test oj.compile method for generating dom structure with bound events

path = require 'path'
fs = require 'fs'
async = require 'async'

oj = require '../generated/oj.js'

compileDOM = (ojml, tag, html, options) ->
  options = _.defaults {}, options,
    html:true
    css:false
    dom:true
    debug:false
  r = oj.compile options, ojml
  if options.dom
    if _.isArray r.dom
      for d,ix in r.dom
        expect(oj.typeOf(d)).to.equal 'dom-element'
        if tag?
          expect(d.tagName).to.equal tag[ix].toUpperCase()
        expect(d.outerHTML).to.equal html[ix]
    else
      expect(oj.typeOf(r.dom)).to.equal 'dom-element'
      if tag?
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
      expect(oj.typeOf(r.dom)).to.equal 'dom-text'
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
    compileDOM ojml, 'div', '<div>test</div>'

  it 'div number', ->
    ojml = oj.div 42
    compileDOM ojml, 'div', '<div>42</div>'

  it 'div boolean', ->
    ojml = oj.div false
    compileDOM ojml, 'div', '<div>false</div>'
    ojml = oj.div true
    compileDOM ojml, 'div', '<div>true</div>'

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
    compileDOM ojml, 'span', '<span>test</span>'

  it 'opened', ->
    ojml = oj.hr()
    compileDOM ojml, 'hr', '<hr />'

  it 'closed', ->
    ojml = oj.div()
    compileDOM ojml, 'div', '<div></div>'

  it 'nested divs', ->
    ojml = oj.div oj.div 'test'
    compileDOM ojml, 'div', '<div><div>test</div></div>'

  it 'attributes empty', ->
    ojml = oj.div {}, ->
    compileDOM ojml, 'div', '<div></div>'

  it 'attributes class', ->
    ojml = oj.div class: 'c1', ->
    compileDOM ojml, 'div', '<div class="c1"></div>'

  it 'attributes class with c', ->
    ojml = oj.div c: 'c1', ->
    compileDOM ojml, 'div', '<div class="c1"></div>'

  it 'attributes id', ->
    ojml = oj.div id: 'id1', ->
    compileDOM ojml, 'div', '<div id="id1"></div>'

  it 'attributes string', ->
    ojml = oj.div attr: 'str', ->
    compileDOM ojml, 'div', '<div attr="str"></div>'
    ojml = oj.div attr: '', ->
    compileDOM ojml, 'div', '<div attr=""></div>'

  it 'attributes boolean', ->
    ojml = oj.div attr: true
    # js-dom has a bug where this should be: <div attr></div>
    compileDOM ojml, 'div', '<div attr=""></div>'
    ojml = oj.div attr: false
    compileDOM ojml, 'div', '<div></div>'

  it 'attributes undefined', ->
    ojml = oj.div attr: undefined
    compileDOM ojml, 'div', '<div></div>'

  it 'attributes null', ->
    ojml = oj.div attr: null
    compileDOM ojml, 'div', '<div></div>'

  it 'attributes multiple', ->
    ojml = oj.div class: 'c1', id: 'id1', ->
    compileDOM ojml, 'div', '<div class="c1" id="id1"></div>'

  it 'attributes style string', ->
    ojml = oj.div style: 'text-align:center; color:red', ->
    compileDOM ojml, 'div', '<div style="text-align:center; color:red"></div>'

  it 'attributes style object', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
    compileDOM ojml, 'div', '<div style="color:red;text-align:center"></div>'

  it 'attributes style object with fancy keys', ->
    ojml = oj.div style: {textAlign:'center', color: 'red'}, ->
    compileDOM ojml, 'div', '<div style="color:red;text-align:center"></div>'

  it 'simple nested', ->
    ojml = oj.div ->
      oj.span 'a1'
    expected = '<div><span>a1</span></div>'
    compileDOM ojml, 'div', expected, debug: false

  it 'nested', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
      oj.div 'a1', ->
        oj.div 'b1'
      oj.div 'a2'
    expected = '<div style="color:red;text-align:center"><div>a1<div>b1</div></div><div>a2</div></div>'
    compileDOM ojml, 'div', expected, debug: false

  # Debug should have no effect on dom creation
  it 'nested with debug printing', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
      oj.div 'a1', ->
        oj.div 'b1'
      oj.div 'a2'
    expected = '<div style="color:red;text-align:center"><div>a1<div>b1</div></div><div>a2</div></div>'
    compileDOM ojml, 'div', expected, debug: true

  it '<html><body>', ->
    ojml = oj.html ->
      oj.body ->
        oj.div 'a1'
    expected = '<html><body><div>a1</div></body></html>'
    compileDOM ojml, 'html', expected, debug: false

  it '<html><body> with debug printing', ->
    ojml = oj.html ->
      oj.body ->
        oj.div 'a1'
    expected = '<html><body><div>a1</div></body></html>'
    compileDOM ojml, 'html', expected, debug: true

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
    compileDOM ojml, 'body', expected, ignore: {html:1, doctype:1, head:1, link:1, script:1}

  # Note: DOCTYPE is completely unsupported through dom creation because it is not really an element
  # The unit test should ignore it.
  it 'doctype', ->
    ojml = oj ->
      oj.doctype()
      oj.html()

    expected = '<html></html>'
    compileDOM ojml, null, expected, ignore: {}

    ojml = oj ->
      oj.doctype 5
      oj.html()

    expected = '<html></html>'
    compileDOM ojml, null, expected, ignore: {}

    ojml = oj ->
      oj.doctype('HTML 4.01 Transitional')
      oj.html ->
        oj.head()
        oj.body ->
          oj.div 'test'

    expected = '<html><head></head><body><div>test</div></body></html>'
    compileDOM ojml, null, expected, ignore: {}
