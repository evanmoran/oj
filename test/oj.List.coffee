# oj.List.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.List', ->

  beforeEach ->
    $('body').html ''

  it 'exists', ->
    expect(oj.List).to.be.a 'function'

  it 'construct default', ->
    control = oj.List()
    expect(oj.isOJ control).to.equal true
    expect(oj.typeOf control).to.equal 'List'
    expect(control.count).to.equal 0
    expect(control.items).to.deep.equal []

  it 'construct with id', ->
    id = 'my-id'
    control = oj.List id:id
    expect(control.count).to.equal 0
    expect(control.id).to.equal id
    expect(control.attributes.id).to.equal id

  it 'construct with name', ->
    name = 'my-name'
    control = oj.List name:name
    expect(control.count).to.equal 0
    expect(control.name).to.not.exist
    expect(control.attributes.name).to.equal name

  it 'construct with one argument', ->
    control = oj.List 1
    expect(oj.typeOf control).to.equal 'List'
    expect(control.count).to.equal 1
    expect(control.items).to.deep.equal [1]

    html = oj.toHTML control
    expect(html).to.contain '<ul'
    expect(html).to.contain '<li>1</li>'
    expect(html).to.contain '</ul>'

  it 'construct with two argument', ->
    control = oj.List 1,2
    expect(oj.typeOf control).to.equal 'List'
    expect(control.count).to.equal 2
    expect(control.items).to.deep.equal [1,2]

    html = oj.toHTML control
    expect(html).to.contain '<ul'
    expect(html).to.contain '<li>1</li>'
    expect(html).to.contain '<li>2</li>'
    expect(html).to.contain '</ul>'

  it 'construct with empty models argument', ->
    control = oj.List models:[]
    expect(control.count).to.equal 0
    expect(oj.typeOf control).to.equal 'List'
    expect(control.items).to.deep.equal []

  it 'construct from element', ->
    $('body').html """
      <ul>
        <li>one</li>
        <li>2</li>
        <li></li>
      </ul>
    """

    $list = $('ul')

    control = oj.List el:$list[0]
    expect(oj.typeOf control).to.equal 'List'
    expect(control.count).to.equal 3

    expect(control.item(0)).to.equal 'one'
    expect(control.item(1)).to.equal 2
    expect(control.item(2)).to.not.exist

    expect(control.items).to.deep.equal ['one', 2, undefined]

  # it 'construct with one model argument', ->
  #   control = oj.List models:[1]
  #   expect(control.count).to.equal 1
  #   expect(oj.typeOf control).to.equal 'List'
  #   expect(control.items).to.deep.equal [1]

  #   html = oj.toHTML control
  #   expect(html).to.contain '<ul'
  #   expect(html).to.contain '<li>1</li>'
  #   expect(html).to.contain '</ul>'
