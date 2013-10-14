# oj.TextBox.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../src/oj.js'

describe 'oj.TextBox', ->
  it 'exists', ->
    expect(oj.TextBox).to.be.a 'function'

  it 'construct default', ->
    control = oj.TextBox()
    expect(oj.isOJ control).to.equal true
    expect(control.typeName).to.equal 'TextBox'
    expect(control.value).to.equal ''
    control.value = 'test'
    expect(control.value).to.equal 'test'

  it 'construct with value:"test"', ->
    control = oj.TextBox value:"test"
    expect(control.typeName).to.equal 'TextBox'
    expect(control.value).to.equal "test"

  it 'construct with id', ->
    id = 'my-id'
    control = oj.TextBox id:id
    expect(control.id).to.equal id
    expect(control.attributes.id).to.equal id

  it 'construct with name', ->
    name = 'my-name'
    control = oj.TextBox name:name
    expect(control.name).to.not.exist
    expect(control.attributes.name).to.equal name

  it 'compile html', ->
    control = oj.TextBox(value:'test')
    results = oj.compile html:true, dom:true, control
    expect(results.html).to.contain '<input'
    expect(results.html).to.not.contain 'id'
    expect(results.html).to.contain 'value="test"'
