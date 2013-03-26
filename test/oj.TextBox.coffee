# oj.TextBox.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.TextBox', ->
  it 'exists', ->
    assert oj.TextBox != null, 'oj.TextBox is null'
    oj.TextBox.should.be.a 'function'

  it 'construct default', ->
    tb = oj.TextBox()
    expect(oj.isOJ tb).to.equal true
    expect(oj.typeOf tb).to.equal 'TextBox'
    expect(tb.value).to.equal ''
    tb.value = 'test'
    expect(tb.value).to.equal 'test'

  it 'construct with value:"test"', ->
    tb = oj.TextBox value:"test"
    expect(oj.typeOf tb).to.equal 'TextBox'
    expect(tb.value).to.equal "test"

  it 'construct with name', ->
    name = 'TextBoxName'
    tb = oj.TextBox name:name
    expect(tb.name).to.not.exist
    expect(tb.attributes.name).to.equal name

  it 'compile html', ->
    tb = oj.TextBox(value:'test')
    results = oj.compile html:true, dom:true, tb
    expect(results.html).to.contain '<input'
    expect(results.html).to.contain 'id="oj'
    expect(results.html).to.contain 'value="test"'
