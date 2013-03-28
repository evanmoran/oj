# oj.List.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.List', ->
  it 'exists', ->
    expect(oj.List).to.be.a 'function'

  it 'construct default', ->
    control = oj.List()
    expect(oj.isOJ control).to.equal true
    expect(oj.typeOf control).to.equal 'List'
    expect(control.value).to.equal false

  it 'construct with id', ->
    id = 'my-id'
    control = oj.List id:id
    expect(control.id).to.not.exist
    expect(control.attributes.id).to.equal id

  it 'construct with name', ->
    name = 'my-name'
    control = oj.List name:name
    expect(control.name).to.not.exist
    expect(control.attributes.name).to.equal name

  it 'construct with one argument', ->
    control = oj.List 1
    expect(oj.typeOf control).to.equal 'List'
    expect(control.value).to.equal true
    html = oj.toHTML control
    expect(html).to.contain '<ul'
    expect(html).to.contain '<li>1</li>'
    expect(html).to.contain '</ul>'
