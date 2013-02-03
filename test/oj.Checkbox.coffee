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

  it 'default checkbox', ->
    checkbox = oj.Checkbox()
    expect(oj.typeOf checkbox).to.equal 'Checkbox'
    expect(checkbox.value).to.equal false
    # expect(oj.disabled).to.equal false
    # expect(oj.hidden).to.equal false
