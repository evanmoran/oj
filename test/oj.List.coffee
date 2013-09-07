# oj.List.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
Backbone = require 'backbone'
oj = require '../generated/oj.js'

contains = (control, args...) ->
  html = oj.toHTML control
  for arg in args
    expect(html).to.contain arg

jsonify = (any) ->
  if oj.isString(any) or oj.isNumber(any) or oj.isBoolean(any)
    '' + any
  else
    JSON.stringify any

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

    contains control,
      'class="oj-List"'
      '<div'
      '<div>1</div>'
      '</div>'

  it 'construct with two arguments', ->
    control = oj.List 1,2
    expect(oj.typeOf control).to.equal 'List'
    expect(control.count).to.equal 2
    expect(control.items).to.deep.equal [1,2]

    contains control,
      'class="oj-List"'
      '<div'
      '<div>1</div>'
      '<div>2</div>'
      '</div>'

  it 'construct with empty models argument', ->
    control = oj.List models:[]
    expect(control.count).to.equal 0
    expect(oj.typeOf control).to.equal 'List'
    expect(control.items).to.deep.equal []

  it 'tagName and itemTagName', ->
    control = oj.List 1, 2, tagName:'span', itemTagName:'div'
    expect(oj.typeOf control).to.equal 'List'
    expect(control.count).to.equal 2
    expect(control.items).to.deep.equal [1,2]

    contains control,
      'class="oj-List"'
      '<span'
      '<div>1</div>'
      '<div>2</div>'
      '</span>'

  it 'remove, add', ->
    control = oj.List 1,2,3
    expect(control.count).to.equal 3
    expect(oj.typeOf control).to.equal 'List'
    expect(control.items).to.deep.equal [1,2,3]

    r = control.remove(1)
    expect(r).to.equal 2
    expect(control.items).to.deep.equal [1,3]

    r = control.remove(1)
    expect(r).to.equal 3
    expect(control.items).to.deep.equal [1]

    r = control.remove(0)
    expect(r).to.equal 1
    expect(control.items).to.deep.equal []

    expect(-> control.remove(1)).to.throw Error
    expect(-> control.add(1,4)).to.throw Error

    control.add(0,4)
    expect(control.items).to.deep.equal [4]

    control.add(1,5)
    expect(control.items).to.deep.equal [4,5]

    control.add(1,6)
    expect(control.items).to.deep.equal [4,6,5]

  it 'shift, unshift', ->
    control = oj.List 1,2,3
    expect(control.count).to.equal 3
    expect(oj.typeOf control).to.equal 'List'
    expect(control.items).to.deep.equal [1,2,3]

    r = control.shift()
    expect(r).to.equal 1
    expect(control.items).to.deep.equal [2,3]

    r = control.shift()
    expect(r).to.equal 2
    expect(control.items).to.deep.equal [3]

    r = control.shift()
    expect(r).to.equal 3
    expect(control.items).to.deep.equal []

    expect(-> control.shift()).to.throw Error
    control.unshift(4)
    expect(control.items).to.deep.equal [4]

    control.unshift(5)
    expect(control.items).to.deep.equal [5,4]

  it 'pop, push', ->
    control = oj.List 1,2,3
    expect(control.count).to.equal 3
    expect(oj.typeOf control).to.equal 'List'
    expect(control.items).to.deep.equal [1,2,3]

    r = control.pop()
    expect(r).to.equal 3
    expect(control.items).to.deep.equal [1,2]

    r = control.pop()
    expect(r).to.equal 2
    expect(control.items).to.deep.equal [1]

    r = control.pop()
    expect(r).to.equal 1
    expect(control.items).to.deep.equal []

    expect(-> control.pop()).to.throw Error
    control.push(4)
    expect(control.items).to.deep.equal [4]

    control.push(5)
    expect(control.items).to.deep.equal [4,5]

  it 'NumberList', ->
    control = oj.NumberList 1,2
    expect(oj.typeOf control).to.equal 'NumberList'
    expect(control.count).to.equal 2
    expect(control.items).to.deep.equal [1,2]

    contains control,
      'class="oj-NumberList"'
      '<ol'
      '<li>1</li>'
      '<li>2</li>'
      '</ol>'

    it 'BulletList', ->
    control = oj.BulletList 1,2
    expect(oj.typeOf control).to.equal 'BulletList'
    expect(control.count).to.equal 2
    expect(control.items).to.deep.equal [1,2]

    contains control,
      'class="oj-BulletList"'
      '<ul'
      '<li>1</li>'
      '<li>2</li>'
      '</ul>'

  it 'construct with one model argument (default each)', ->
    control = oj.List models:[1]
    expect(control.count).to.equal 1
    expect(oj.typeOf control).to.equal 'List'
    expect(control.typeName).to.equal 'List'

    contains control,
      '<div>1</div>'

    expect(control.items).to.deep.equal [1]

  it 'construct with many models (default each)', ->
    user1 = name:'Alfred', strength: 11
    user2 = name:'Batman', strength: 22
    user3 = name:'Catwoman', strength: 33
    user4 = name:'Gordan', strength: 44
    control = oj.List models:[user1,user2,user3]

    expect(control.count).to.equal 3
    expect(oj.typeOf control).to.equal 'List'
    expect(control.typeName).to.equal 'List'

    contains control,
      "<div>#{jsonify user1}</div>"
      "<div>#{jsonify user2}</div>"
      "<div>#{jsonify user3}</div>"

    expect(control.items).to.deep.equal [
      jsonify user1
      jsonify user2
      jsonify user3
    ]

  it 'construct with list of backbone models (default each)', ->

    class UserModel extends Backbone.Model
    user1 = new UserModel name:'Alfred', strength: 11
    user2 = new UserModel name:'Batman', strength: 22
    user3 = new UserModel name:'Catwoman', strength: 33
    user4 = new UserModel name:'Gordan', strength: 44
    control = oj.List models:[user1,user2,user3]

    expect(control.count).to.equal 3
    expect(oj.typeOf control).to.equal 'List'
    expect(control.typeName).to.equal 'List'

    contains control,
      "<div>#{jsonify user1}</div>"
      "<div>#{jsonify user2}</div>"
      "<div>#{jsonify user3}</div>"

    expect(control.items).to.deep.equal [
      jsonify user1
      jsonify user2
      jsonify user3
    ]

  it 'construct with collection of backbone models (default each)', ->

    class UserModel extends Backbone.Model
    class UserCollection extends Backbone.Collection
      model: UserModel
      comparator: (m) -> m.get 'name'

    user1 = new UserModel name:'Alfred', strength: 11
    user2 = new UserModel name:'Batman', strength: 22
    user3 = new UserModel name:'Catwoman', strength: 33
    user4 = new UserModel name:'Gordan', strength: 44

    users = new UserCollection [user3, user1]

    control = oj.List models:users

    expect(control.count).to.equal 2
    expect(oj.typeOf control).to.equal 'List'
    expect(control.typeName).to.equal 'List'

    contains control,
      "<div>#{jsonify user1}</div>"
      "<div>#{jsonify user3}</div>"

    expect(control.items).to.deep.equal [
      jsonify user1
      jsonify user3
    ]

    # Add element
    users.add [user2]

    contains control,
      "<div>#{jsonify user1}</div>"
      "<div>#{jsonify user2}</div>"
      "<div>#{jsonify user3}</div>"

    expect(control.items).to.deep.equal [
      jsonify user1
      jsonify user2
      jsonify user3
    ]

    # Remove element
    users.remove user1

    contains control,
      "<div>#{jsonify user2}</div>"
      "<div>#{jsonify user3}</div>"

    expect(control.items).to.deep.equal [
      jsonify user2
      jsonify user3
    ]

    # Reset elements
    users.reset user4

    contains control,
      "<div>#{jsonify user4}</div>"

    expect(control.items).to.deep.equal [
      jsonify user4
    ]


  it 'construct with collection of backbone models (manual each)', ->

    namify = (model) ->
      model.get 'name'

    class UserModel extends Backbone.Model
    class UserCollection extends Backbone.Collection
      model: UserModel
      comparator: namify

    user1 = new UserModel name:'Alfred', strength: 11
    user2 = new UserModel name:'Batman', strength: 22
    user3 = new UserModel name:'Catwoman', strength: 33
    user4 = new UserModel name:'Gordan', strength: 44

    users = new UserCollection [user3, user1]

    control = oj.List models:users, each:namify

    expect(control.count).to.equal 2
    expect(oj.typeOf control).to.equal 'List'
    expect(control.typeName).to.equal 'List'

    contains control,
      "<div>#{namify user1}</div>"
      "<div>#{namify user3}</div>"

    expect(control.items).to.deep.equal [
      namify user1
      namify user3
    ]

    # Add element
    users.add [user2]

    contains control,
      "<div>#{namify user1}</div>"
      "<div>#{namify user2}</div>"
      "<div>#{namify user3}</div>"

    expect(control.items).to.deep.equal [
      namify user1
      namify user2
      namify user3
    ]

    # Remove element
    users.remove user1

    contains control,
      "<div>#{namify user2}</div>"
      "<div>#{namify user3}</div>"

    expect(control.items).to.deep.equal [
      namify user2
      namify user3
    ]

    # Reset elements
    users.reset user4

    contains control,
      "<div>#{namify user4}</div>"

    expect(control.items).to.deep.equal [
      namify user4
    ]

  it 'BulletList from element', ->
    $('body').html """
      <ul>
        <li>one</li>
        <li>2</li>
        <li></li>
      </ul>
    """

    $list = $('ul')

    control = oj.BulletList el:$list[0]
    expect(oj.typeOf control).to.equal 'BulletList'
    expect(control.count).to.equal 3

    expect(control.item(0)).to.equal 'one'
    expect(control.item(1)).to.equal 2
    expect(control.item(2)).to.not.exist

    expect(control.items).to.deep.equal ['one', 2, undefined]


  it 'NumberList from element', ->
    $('body').html """
      <ol>
        <li>one</li>
        <li>2</li>
        <li></li>
      </ol>
    """

    $list = $('ol')

    control = oj.NumberList el:$list[0]
    expect(oj.typeOf control).to.equal 'NumberList'
    expect(control.count).to.equal 3

    expect(control.item(0)).to.equal 'one'
    expect(control.item(1)).to.equal 2
    expect(control.item(2)).to.not.exist

    expect(control.items).to.deep.equal ['one', 2, undefined]


  it 'List from element', ->
    $('body').html """
      <div>
        <div>one</div>
        <div>2</div>
        <div></div>
      </div>
    """

    $list = $('body > div')

    control = oj.List el:$list[0]
    expect(oj.typeOf control).to.equal 'List'
    expect(control.count).to.equal 3

    expect(control.item(0)).to.equal 'one'
    expect(control.item(1)).to.equal 2
    expect(control.item(2)).to.not.exist

    expect(control.items).to.deep.equal ['one', 2, undefined]

