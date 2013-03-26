# oj.CheckBox.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.CheckBox', ->
  it 'exists', ->
    assert oj.CheckBox != null, 'oj.CheckBox is null'
    oj.CheckBox.should.be.a 'function'

  it 'construct default', ->
    cb = oj.CheckBox()
    expect(oj.isOJ cb).to.equal true
    expect(oj.typeOf cb).to.equal 'CheckBox'
    expect(cb.value).to.equal false

  it 'construct with value:true', ->
    cb = oj.CheckBox value:true
    expect(oj.typeOf cb).to.equal 'CheckBox'
    expect(cb.value).to.equal true

  it 'construct with name', ->
    name = 'CheckBoxName'
    cb = oj.CheckBox name:name
    expect(cb.name).to.not.exist
    expect(cb.attributes.name).to.equal name

  it 'compile html', ->
    cb = oj.CheckBox(value:true)
    results = oj.compile html:true, dom:true, cb
    expect(results.html).to.contain '<input'
    expect(results.html).to.contain 'id="oj'
    expect(results.html).to.contain 'class="CheckBox"'
    expect(results.html).to.contain 'checked="checked"'
