# oj.TextArea.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../lib/oj.js'
oj.extend this

describe 'oj.TextArea', ->
  it 'exists', ->
    expect(oj.TextArea).to.be.a 'function'

  it 'construct default', ->
    control = oj.TextArea()
    expect(oj.isOJ control).to.equal true
    expect(oj.typeOf control).to.equal 'TextArea'
    expect(control.value).to.equal ''
    control.value = 'test'
    expect(control.value).to.equal 'test'

  it 'construct with value:"test"', ->
    control = oj.TextArea value:"test"
    expect(oj.typeOf control).to.equal 'TextArea'
    expect(control.value).to.equal "test"

  it 'construct with id', ->
    id = 'my-id'
    control = oj.TextArea id:id
    expect(control.id).to.equal id
    expect(control.attributes.id).to.equal id

  it 'construct with name', ->
    name = 'my-name'
    control = oj.TextArea name:name
    expect(control.name).to.not.exist
    expect(control.attributes.name).to.equal name

  it 'compile html', ->
    control = oj.TextArea(value:'test')
    results = oj.compile html:true, dom:true, control
    expect(results.html).to.contain '<textarea'
    expect(results.html).to.contain 'class="oj-TextArea"'
    expect(results.html).to.contain 'id="oj'
    expect(results.html).to.contain 'test</textarea>'
