# oj.CheckBox.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../oj.js'

describe 'oj.CheckBox', ->
  it 'exists', ->
    assert oj.CheckBox != null, 'oj.CheckBox is null'
    oj.CheckBox.should.be.a 'function'

  it 'construct default', ->
    control = oj.CheckBox()
    expect(oj.isOJ control).to.equal true
    expect(control.typeName).to.equal 'CheckBox'
    expect(control.value).to.equal false

  it 'construct with value:true', ->
    control = oj.CheckBox value:true
    expect(control.typeName).to.equal 'CheckBox'
    expect(control.value).to.equal true

  it 'construct with id', ->
    id = 'my-id'
    control = oj.CheckBox id:id
    expect(control.id).to.equal id
    expect(control.attributes.id).to.equal id

  # it 'construct with class', ->
  #   cls = 'my-class'
  #   control = oj.CheckBox class:cls
  #   expect(control.class).to.equal cls
  #   expect(control.attributes.class).to.equal cls

  #   cls2 = 'my-class2'
  #   cls3 = 'my-class3'
  #   control.class = [cls2,cls3]
  #   expect(control.classes).to.deep.equal cls


  it 'construct with name', ->
    name = 'my-name'
    control = oj.CheckBox name:name
    expect(control.name).to.not.exist
    expect(control.attributes.name).to.equal name


  it 'compile html', ->
    control = oj.CheckBox(value:true)
    results = oj.compile html:true, dom:true, control
    expect(results.html).to.contain '<input'
    expect(results.html).to.not.contain 'id'
    expect(results.html).to.contain 'class="oj-CheckBox"'
    expect(results.html).to.contain 'checked="checked"'

  it 'compile with new keyword', ->
    control = null

    htmlDiv = oj.toHTML ->
      oj.div c:'test', ->
        control = new oj.CheckBox value:true
        return

    expect(control.typeName).to.equal 'CheckBox'
    expect(control.value).to.equal true
    expect(htmlDiv).to.equal '<div class="test"></div>'

    htmlDiv2 = oj.toHTML minify:true, ->
      oj.div c:'test2', ->
        control.emit()

    expect(htmlDiv2).to.equal """<div class="test2"><input type="checkbox" checked="checked" class="#{control.attributes.class}" /></div>"""
