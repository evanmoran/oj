# oj.Table.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.Table', ->
  # it 'exists', ->
  #   expect(oj.Table).to.be.a 'function'

  # it 'construct default', ->
  #   control = oj.Table()
  #   expect(oj.isOJ control).to.equal true
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.value).to.equal false

  # it 'construct with value:true', ->
  #   control = oj.Table value:true
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.value).to.equal true

  # it 'construct with id', ->
  #   id = 'my-id'
  #   control = oj.Table id:id
  #   expect(control.id).to.not.exist
  #   expect(control.attributes.id).to.equal id

  # it 'construct with name', ->
  #   name = 'my-name'
  #   control = oj.Table name:name
  #   expect(control.name).to.not.exist
  #   expect(control.attributes.name).to.equal name

  # it 'compile html', ->
  #   control = oj.Table(value:true)
  #   results = oj.compile html:true, dom:true, control
  #   expect(results.html).to.contain '<input'
  #   expect(results.html).to.contain 'id="oj'
  #   expect(results.html).to.contain 'class="Table"'
  #   expect(results.html).to.contain 'checked="checked"'
