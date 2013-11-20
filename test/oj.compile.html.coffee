# test/oj.compile.html.coffee
#
# Test oj.compile method for generating html, css, javascript

path = require 'path'
fs = require 'fs'
async = require 'async'

oj = require '../oj.js'

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

compileTest = (ojml, html, options = {}) ->
  options = _.defaults {}, options,
    html:true
    css:true
    dom:false
    minify:true
    body:false

  r = oj.compile options, ojml
  if not (options.html == false)
    expect(r.html).to.be.a 'string'
    expect(r.html).to.equal html
  else
    expect(r.html).to.not.exist

compileTestException = (ojml, exception, options = {}) ->
  expect(-> oj.compile options, ojml).to.throw exception

describe 'oj.compile.html', ->
  beforeEach ->
    _clear $('body')

  it 'exists', ->
    expect(oj.compile).to.exist
    oj.compile.should.be.a 'function'

  it 'oj.toHTML (not minified)'

  it 'oj.toHTML (minified)', ->
    ojml = oj.html ->
      oj.head ->
        oj.script type: 'text/javascript', src: 'script.js'
      oj.body ->
        oj.div 'a1'
    result = oj.toHTML({minify:true}, ojml)
    expected = '<html><head><script src="script.js" type="text/javascript"></script></head><body><div>a1</div></body></html>'
    expect(result).to.equal expected

  it 'div', ->
    ojml = oj.div 'test'
    compileTest ojml, '<div>test</div>'

  it 'values', ->
    compileTest '', ''
    compileTest 'test', 'test'
    compileTest 42, '42'
    compileTest true, 'true'
    compileTest false, 'false'
    compileTest [], ''
    compileTest (->), ''
    compileTest null, ''
    compileTest undefined, ''

  it 'span', ->
    ojml = oj.span 'test'
    compileTest ojml, '<span>test</span>'

  it 'opened', ->
    ojml = oj.hr()
    compileTest ojml, '<hr>'

  it 'closed', ->
    ojml = oj.div()
    compileTest ojml, '<div></div>'

  it 'nested divs', ->
    ojml = oj.div oj.div 'test'
    compileTest ojml, '<div><div>test</div></div>'

  it 'attributes empty', ->
    ojml = oj.div {}, ->
    compileTest ojml, '<div></div>'

  it 'attributes class', ->
    ojml = oj.div class: 'c1', ->
    compileTest ojml, '<div class="c1"></div>'

  it 'attributes class with c', ->
    ojml = oj.div c: 'c1', ->
    compileTest ojml, '<div class="c1"></div>'

  it 'attributes class as array', ->
    ojml = oj.div class: ['c1','c2'], ->
    compileTest ojml, '<div class="c1 c2"></div>'

  it 'attributes c as array', ->
    ojml = oj.div c: ['c1','c2'], ->
    compileTest ojml, '<div class="c1 c2"></div>'

  it 'attributes class and c as array', ->
    ojml = oj.div class: ['c1','c2'], c:['c3'], ->
    compileTest ojml, '<div class="c1 c2 c3"></div>'

  it 'attributes class and c as array', ->
    ojml = oj.div class: ['c1','c2'], c:'c3 c4', ->
    compileTest ojml, '<div class="c1 c2 c3 c4"></div>'

  it 'attributes id', ->
    ojml = oj.div id: 'id1', ->
    compileTest ojml, '<div id="id1"></div>'

  it 'attributes string', ->
    ojml = oj.div attr: 'str', ->
    compileTest ojml, '<div attr="str"></div>'
    ojml = oj.div attr: '', ->
    compileTest ojml, '<div attr=""></div>'

  it 'attributes boolean', ->
    ojml = oj.div attr: true
    compileTest ojml, '<div attr></div>'
    ojml = oj.div attr: false
    compileTest ojml, '<div></div>'

  it 'attributes undefined', ->
    ojml = oj.div attr: undefined
    compileTest ojml, '<div></div>'

  it 'attributes null', ->
    ojml = oj.div attr: null
    compileTest ojml, '<div></div>'

  it 'attributes multiple', ->
    ojml = oj.div class: 'c1', id: 'id1', ->
    compileTest ojml, '<div class="c1" id="id1"></div>'

  it 'attributes style string', ->
    ojml = oj.div style: 'text-align:center; color:red', ->
    compileTest ojml, '<div style="text-align:center; color:red"></div>'

  it 'attributes style object', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
    compileTest ojml, '<div style="color:red;text-align:center"></div>'

  it 'attributes style object with fancy keys', ->
    ojml = oj.div style: {textAlign:'center', color: 'red'}, ->
    compileTest ojml, '<div style="color:red;text-align:center"></div>'

  it 'simple nested', ->
    ojml = oj.div ->
      oj.span 'a1'
    expected = '<div><span>a1</span></div>'
    compileTest ojml, expected, minify: true

  it 'nested', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
      oj.div 'a1', ->
        oj.div 'b1'
      oj.div 'a2'
    expected = '<div style="color:red;text-align:center"><div>a1<div>b1</div></div><div>a2</div></div>'
    compileTest ojml, expected, minify: true

  it 'nested with debug printing', ->
    ojml = oj.div style: {'text-align':'center', color: 'red'}, ->
      oj.div 'a1', ->
        oj.div 'b1'
      oj.div 'a2'
    expected = '<div style="color:red;text-align:center">\n\t<div>\n\t\ta1\n\t\t<div>b1</div>\n\t</div>\n\t<div>a2</div>\n</div>'
    compileTest ojml, expected, minify: false

  it '<html><body>', ->
    ojml = oj.html ->
      oj.body ->
        oj.div 'a1'
    expected = '<html><body><div>a1</div></body></html>'
    compileTest ojml, expected, minify: true

  it '<html><body> with debug printing', ->
    ojml = oj.html ->
      oj.body ->
        oj.div 'a1'
    expected = '<html><body><div>a1</div></body></html>'
    compileTest ojml, expected, minify: false

  it '<html><head><body>', ->
      ojml = oj.html ->
        oj.head ->
          oj.script type: 'text/javascript', src: 'script.js'
        oj.body ->
          oj.div 'a1'
          # css should be ignored in structure
          oj.css '.selector':color:'red'
      expected = '<html><head><script src="script.js" type="text/javascript"></script></head><body><div>a1</div></body></html>'
      compileTest ojml, expected, minify: true

  it '<html><head><body> with debug printing', ->
    ojml = oj.html ->
      oj.head ->
        oj.script type: 'text/javascript', src: 'script.js'
      oj.body ->
        oj.div 'a1'
    expected = '<html>\n\t<head><script src="script.js" type="text/javascript"></script></head>\n\t<body><div>a1</div></body>\n</html>'
    compileTest ojml, expected, minify: false

  it '<html><head><body> with ignore', ->
    ojml = oj.html ->
      oj.head ->
        oj.script type: 'text/javascript', src: 'script.js'
      oj.body ->
        oj.div 'a1'
    expected = '<body><div>a1</div></body>'
    compileTest ojml, expected, ignore: {html:1, doctype:1, head:1, link:1, script:1}

  it 'doctype', ->
    ojml = oj.doctype()
    expected = '<!DOCTYPE html>'
    compileTest ojml, expected, ignore: {}

    ojml = oj ->
      oj.doctype()
      oj.html ->
        oj.head()
        oj.body ->
          oj.div 'test'

    expected = '<!DOCTYPE html><html><head></head><body><div>test</div></body></html>'
    compileTest ojml, expected, ignore: {}

    ojml = oj.doctype 5
    expected = '<!DOCTYPE html>'
    compileTest ojml, expected, ignore: {}

    ojml = oj.doctype('HTML 5')
    expected = '<!DOCTYPE html>'
    compileTest ojml, expected, ignore: {}

    ojml = oj.doctype 4
    expected = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
    compileTest ojml, expected, ignore: {}

    ojml = oj.doctype('HTML 4.01 Strict')
    expected = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
    compileTest ojml, expected, ignore: {}

    ojml = oj.doctype('HTML 4.01 Transitional')
    expected = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'
    compileTest ojml, expected, ignore: {}

    ojml = oj.doctype('HTML 4.01 Frameset')
    expected = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">'
    compileTest ojml, expected, ignore: {}
