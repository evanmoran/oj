# oj.Checkbox.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.Checkbox', ->
  it 'exists', ->
    assert oj.Checkbox != null, 'oj.Checkbox is null'
    oj.Checkbox.should.be.a 'function'

  it 'construct default', ->
    checkbox = oj.Checkbox()
    expect(oj.typeOf checkbox).to.equal 'Checkbox'
    expect(checkbox.value).to.equal false
    expect(checkbox.id).to.be.a 'string'
    checkbox.id = 'oj123'
    expect(checkbox.id).to.equal 'oj123'

  it 'construct with value:true', ->
    checkbox = oj.Checkbox value: true
    expect(oj.typeOf checkbox).to.equal 'Checkbox'
    expect(checkbox.value).to.equal true

  it 'setting value', ->
    checkbox = oj.Checkbox value: true
    expect(oj.typeOf checkbox).to.equal 'Checkbox'
    checkbox.value = false
    # expect(oj.disabled).to.equal false
    # expect(oj.hidden).to.equal false
