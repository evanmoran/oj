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
    checkbox = oj.CheckBox()
    expect(oj.isOJ checkbox).to.equal true
    expect(oj.typeOf checkbox).to.equal 'CheckBox'
    expect(checkbox.value).to.equal false

  it 'construct with value:true', ->
    checkbox = oj.CheckBox value:true
    expect(oj.typeOf checkbox).to.equal 'CheckBox'
    expect(checkbox.value).to.equal true

  it 'compile html', ->
    checkbox = oj.CheckBox(value:true)
    results = oj.compile html:true, dom:true, checkbox
    expect(results.html).to.contain '<input'
    expect(results.html).to.contain 'id="oj'
    expect(results.html).to.contain 'class="CheckBox"'
    expect(results.html).to.contain 'checked="checked"'

  it 'compile dom'
    # checkbox = oj.CheckBox()
    # results = oj.compile html:true, dom:true, checkbox
    # expect($(results.dom.outerHTML).attr()).to.equal '<input type="checkbox">'

  it 'setting value'
    # checkbox = oj.CheckBox value: true
    # expect(oj.typeOf checkbox).to.equal 'CheckBox'
    # checkbox.value = false
    # expect(oj.disabled).to.equal false
    # expect(oj.hidden).to.equal false
