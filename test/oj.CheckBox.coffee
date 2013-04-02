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
    control = oj.CheckBox()
    expect(oj.isOJ control).to.equal true
    expect(oj.typeOf control).to.equal 'CheckBox'
    expect(control.value).to.equal false

  it 'construct with value:true', ->
    control = oj.CheckBox value:true
    expect(oj.typeOf control).to.equal 'CheckBox'
    expect(control.value).to.equal true

  it 'construct with id', ->
    id = 'my-id'
    control = oj.CheckBox id:id
    expect(control.id).to.equal id
    expect(control.attributes.id).to.equal id

  it 'construct with name', ->
    name = 'my-name'
    control = oj.CheckBox name:name
    expect(control.name).to.not.exist
    expect(control.attributes.name).to.equal name

  it 'compile html', ->
    control = oj.CheckBox(value:true)
    results = oj.compile html:true, dom:true, control
    expect(results.html).to.contain '<input'
    expect(results.html).to.contain 'id="oj'
    expect(results.html).to.contain 'class="CheckBox"'
    expect(results.html).to.contain 'checked="checked"'
