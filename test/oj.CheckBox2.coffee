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

  it 'construct default'
    # checkbox = oj.CheckBox()
    # expect(oj.isOJ checkbox).to.equal true
    # expect(oj.typeOf checkbox).to.equal 'CheckBox'
    # expect(checkbox.id).to.be.a 'string'
    # expect(checkbox.value).to.equal false

  it 'construct with value:true'
    # checkbox = oj.CheckBox value: true
    # expect(oj.typeOf checkbox).to.equal 'CheckBox'
    # expect(checkbox.value).to.equal true

  it 'compile default'
    # checkbox = oj.CheckBox()
    # results = oj.compile html:true, checkbox
    # expect(results.html).to.equal '<input type="checkbox">'

  it 'setting value'
    # checkbox = oj.CheckBox value: true
    # expect(oj.typeOf checkbox).to.equal 'CheckBox'
    # checkbox.value = false
    # expect(oj.disabled).to.equal false
    # expect(oj.hidden).to.equal false
