# oj.Table.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
Backbone = require 'backbone'
oj = require '../lib/oj.js'
oj.extend this

contains = (control, args...) ->
  html = oj.toHTML control
  for arg in args
    expect(html).to.contain arg

jsonify = (any) ->
  if oj.isString(any) or oj.isNumber(any) or oj.isBoolean(any)
    '' + any
  else
    JSON.stringify any

describe 'oj.Table', ->

  beforeEach ->
    $('body').html ''

  # it 'exists', ->
  #   expect(oj.Table).to.be.a 'function'

  # it 'construct default', ->
  #   control = oj.Table()
  #   expect(oj.isOJ control).to.equal true
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.rowCount).to.equal 0
  #   expect(control.columnCount).to.equal 0
  #   expect(control.rows).to.deep.equal []

  # it 'construct with id', ->
  #   id = 'my-id'
  #   control = oj.Table id:id
  #   expect(control.rowCount).to.equal 0
  #   expect(control.columnCount).to.equal 0
  #   expect(control.id).to.equal id
  #   expect(control.attributes.id).to.equal id

  # it 'construct with name', ->
  #   name = 'my-name'
  #   control = oj.Table name:name
  #   expect(control.rowCount).to.equal 0
  #   expect(control.columnCount).to.equal 0
  #   expect(control.name).to.not.exist
  #   expect(control.attributes.name).to.equal name

  # it 'construct with invalid argument', ->
  #   expect(-> oj.Table 1).to.throw(Error)

  it 'construct with one argument', ->
    control = oj.Table [1]
    expect(oj.typeOf control).to.equal 'Table'
    expect(control.rowCount).to.equal 1
    expect(control.columnCount).to.equal 1
    expect(control.rows).to.deep.equal [[1]]

    contains control,
      'class="oj-Table"'
      '<table'
      '<tbody'
      '<tr'
      '<td>1</td>'
      '</tr>'
      '</tbody>'
      '</table>'

  it 'construct with two arguments', ->
    control = oj.Table [1],[2]
    expect(oj.typeOf control).to.equal 'Table'
    expect(control.rowCount).to.equal 2
    expect(control.columnCount).to.equal 1

    expect(control.rows).to.deep.equal [ [ 1 ], [ 2 ] ]
    contains control,
      'class="oj-Table"'
      '<table'
      '<tbody'
      '<tr'
      '<td>1</td>'
      '<td>2</td>'
      '</tr>'
      '</tbody>'
      '</table>'

  a1 = 'a1'
  a2 = 'a2'
  a3 = 'a3'
  a4 = 'a4'
  a5 = 'a5'
  b1 = 'b1'
  b2 = 'b2'
  b3 = 'b3'
  b4 = 'b4'
  b5 = 'b5'
  c1 = 'c1'
  c2 = 'c2'
  c3 = 'c3'
  c4 = 'c4'
  c5 = 'c5'
  aRow = [a1,a2,a3]
  bRow = [b1,b2,b3]
  cRow = [c1,c2,c3]

  it 'removeRow, addRow', ->
    control = oj.Table aRow, bRow, cRow
    expect(control.rowCount).to.equal 3
    expect(control.columnCount).to.equal 3
    expect(oj.typeOf control).to.equal 'Table'
    expect(control.rows).to.deep.equal [aRow, bRow, cRow]

    r = control.removeRow(1)
    # expect(r).to.equal bRow
    expect(control.rows).to.deep.equal [aRow,cRow]

    # r = control.removeRow(1)
    # expect(r).to.equal 3
    # expect(control.rows).to.deep.equal [1]

    # r = control.removeRow(0)
    # expect(r).to.equal 1
    # expect(control.rows).to.deep.equal []

    # expect(-> control.removeRow(1)).to.throw Error
    # expect(-> control.add(1,4)).to.throw Error

    # control.addRow(0,4)
    # expect(control.rows).to.deep.equal [4]

    # control.addRow(1,5)
    # expect(control.rows).to.deep.equal [4,5]

    # control.addRow(1,6)
    # expect(control.rows).to.deep.equal [4,6,5]

  # it 'shiftRow, unshiftRow', ->
  #   control = oj.Table 1,2,3
  #   expect(control.rowCount).to.equal 3
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.rows).to.deep.equal [1,2,3]

  #   r = control.shiftRow()
  #   expect(r).to.equal 1
  #   expect(control.rows).to.deep.equal [2,3]

  #   r = control.shiftRow()
  #   expect(r).to.equal 2
  #   expect(control.rows).to.deep.equal [3]

  #   r = control.shiftRow()
  #   expect(r).to.equal 3
  #   expect(control.rows).to.deep.equal []

  #   expect(-> control.shiftRow()).to.throw Error
  #   control.unshiftRow(4)
  #   expect(control.rows).to.deep.equal [4]

  #   control.unshiftRow(5)
  #   expect(control.rows).to.deep.equal [5,4]

  # it 'popRow, pushRow', ->
  #   control = oj.Table 1,2,3
  #   expect(control.rowCount).to.equal 3
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.rows).to.deep.equal [1,2,3]

  #   r = control.popRow()
  #   expect(r).to.equal 3
  #   expect(control.rows).to.deep.equal [1,2]

  #   r = control.popRow()
  #   expect(r).to.equal 2
  #   expect(control.rows).to.deep.equal [1]

  #   r = control.popRow()
  #   expect(r).to.equal 1
  #   expect(control.rows).to.deep.equal []

  #   expect(-> control.popRow()).to.throw Error
  #   control.pushRow(4)
  #   expect(control.rows).to.deep.equal [4]

  #   control.pushRow(5)
  #   expect(control.rows).to.deep.equal [4,5]


  # it 'removeColumn, addColumn', ->
  #   control = oj.Table 1,2,3
  #   expect(control.rowCount).to.equal 3
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.rows).to.deep.equal [1,2,3]

  #   r = control.removeColumn(1)
  #   expect(r).to.equal 2
  #   expect(control.rows).to.deep.equal [1,3]

  #   r = control.removeColumn(1)
  #   expect(r).to.equal 3
  #   expect(control.rows).to.deep.equal [1]

  #   r = control.removeColumn(0)
  #   expect(r).to.equal 1
  #   expect(control.rows).to.deep.equal []

  #   expect(-> control.removeColumn(1)).to.throw Error
  #   expect(-> control.add(1,4)).to.throw Error

  #   control.addColumn(0,4)
  #   expect(control.rows).to.deep.equal [4]

  #   control.addColumn(1,5)
  #   expect(control.rows).to.deep.equal [4,5]

  #   control.addColumn(1,6)
  #   expect(control.rows).to.deep.equal [4,6,5]

  # it 'shiftColumn, unshiftColumn', ->
  #   control = oj.Table 1,2,3
  #   expect(control.rowCount).to.equal 3
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.rows).to.deep.equal [1,2,3]

  #   r = control.shiftColumn()
  #   expect(r).to.equal 1
  #   expect(control.rows).to.deep.equal [2,3]

  #   r = control.shiftColumn()
  #   expect(r).to.equal 2
  #   expect(control.rows).to.deep.equal [3]

  #   r = control.shiftColumn()
  #   expect(r).to.equal 3
  #   expect(control.rows).to.deep.equal []

  #   expect(-> control.shiftColumn()).to.throw Error
  #   control.unshiftColumn(4)
  #   expect(control.rows).to.deep.equal [4]

  #   control.unshiftColumn(5)
  #   expect(control.rows).to.deep.equal [5,4]

  # it 'popColumn, pushColumn', ->
  #   control = oj.Table 1,2,3
  #   expect(control.rowCount).to.equal 3
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.rows).to.deep.equal [1,2,3]

  #   r = control.popColumn()
  #   expect(r).to.equal 3
  #   expect(control.rows).to.deep.equal [1,2]

  #   r = control.popColumn()
  #   expect(r).to.equal 2
  #   expect(control.rows).to.deep.equal [1]

  #   r = control.popColumn()
  #   expect(r).to.equal 1
  #   expect(control.rows).to.deep.equal []

  #   expect(-> control.popColumn()).to.throw Error
  #   control.pushColumn(4)
  #   expect(control.rows).to.deep.equal [4]

  #   control.pushColumn(5)
  #   expect(control.rows).to.deep.equal [4,5]

  # it 'construct with empty models argument', ->
  #   control = oj.Table models:[]
  #   expect(control.rowCount).to.equal 0
  #   expect(-> control.cellCount(0)).to.throw Error
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.rows).to.deep.equal []

  # it 'construct with one model argument (default each)', ->
  #   control = oj.Table models:[1]
  #   expect(oj.typeOf control).to.equal 'Table'
  #   expect(control.typeName).to.equal 'Table'
  #   expect(control.rowCount).to.equal 1

  #   contains control,
  #     '<td>1</td>'

#     expect(control.rows).to.deep.equal ['1']

#   it 'construct with many models (default each)', ->
#     user1 = name:'Alfred', strength: 11
#     user2 = name:'Batman', strength: 22
#     user3 = name:'Catwoman', strength: 33
#     user4 = name:'Gordan', strength: 44
#     control = oj.Table models:[user1,user2,user3]

#     expect(control.rowCount).to.equal 3
#     expect(oj.typeOf control).to.equal 'Table'
#     expect(control.typeName).to.equal 'Table'

#     contains control,
#       "<div>#{jsonify user1}</div>"
#       "<div>#{jsonify user2}</div>"
#       "<div>#{jsonify user3}</div>"

#     expect(control.rows).to.deep.equal [
#       jsonify user1
#       jsonify user2
#       jsonify user3
#     ]

#   it 'construct with collection of backbone models (default each)', ->

#     class UserModel extends Backbone.Model
#     user1 = new UserModel name:'Alfred', strength: 11
#     user2 = new UserModel name:'Batman', strength: 22
#     user3 = new UserModel name:'Catwoman', strength: 33
#     user4 = new UserModel name:'Gordan', strength: 44
#     control = oj.Table models:[user1,user2,user3]

#     expect(control.rowCount).to.equal 3
#     expect(oj.typeOf control).to.equal 'Table'
#     expect(control.typeName).to.equal 'Table'

#     contains control,
#       "<div>#{jsonify user1}</div>"
#       "<div>#{jsonify user2}</div>"
#       "<div>#{jsonify user3}</div>"

#     expect(control.rows).to.deep.equal [
#       jsonify user1
#       jsonify user2
#       jsonify user3
#     ]

#   it 'construct with collection of backbone models (default each)', ->

#     class UserModel extends Backbone.Model
#     class UserCollection extends Backbone.Collection
#       model: UserModel
#       comparator: (m) -> m.get 'name'

#     user1 = new UserModel name:'Alfred', strength: 11
#     user2 = new UserModel name:'Batman', strength: 22
#     user3 = new UserModel name:'Catwoman', strength: 33
#     user4 = new UserModel name:'Gordan', strength: 44

#     users = new UserCollection [user3, user1]

#     control = oj.Table models:users

#     expect(control.rowCount).to.equal 2
#     expect(oj.typeOf control).to.equal 'Table'
#     expect(control.typeName).to.equal 'Table'

#     contains control,
#       "<div>#{jsonify user1}</div>"
#       "<div>#{jsonify user3}</div>"

#     expect(control.rows).to.deep.equal [
#       jsonify user1
#       jsonify user3
#     ]

#     # Add element
#     users.add [user2]

#     contains control,
#       "<div>#{jsonify user1}</div>"
#       "<div>#{jsonify user2}</div>"
#       "<div>#{jsonify user3}</div>"

#     expect(control.rows).to.deep.equal [
#       jsonify user1
#       jsonify user2
#       jsonify user3
#     ]

#     # Remove element
#     users.remove user1

#     contains control,
#       "<div>#{jsonify user2}</div>"
#       "<div>#{jsonify user3}</div>"

#     expect(control.rows).to.deep.equal [
#       jsonify user2
#       jsonify user3
#     ]

#     # Reset elements
#     users.reset user4

#     contains control,
#       "<div>#{jsonify user4}</div>"

#     expect(control.rows).to.deep.equal [
#       jsonify user4
#     ]


#   it 'construct with collection of backbone models (manual each)', ->

#     namify = (model) ->
#       model.get 'name'

#     class UserModel extends Backbone.Model
#     class UserCollection extends Backbone.Collection
#       model: UserModel
#       comparator: namify

#     user1 = new UserModel name:'Alfred', strength: 11
#     user2 = new UserModel name:'Batman', strength: 22
#     user3 = new UserModel name:'Catwoman', strength: 33
#     user4 = new UserModel name:'Gordan', strength: 44

#     users = new UserCollection [user3, user1]

#     control = oj.Table models:users, each:namify

#     expect(control.rowCount).to.equal 2
#     expect(oj.typeOf control).to.equal 'Table'
#     expect(control.typeName).to.equal 'Table'

#     contains control,
#       "<div>#{namify user1}</div>"
#       "<div>#{namify user3}</div>"

#     expect(control.rows).to.deep.equal [
#       namify user1
#       namify user3
#     ]

#     # Add element
#     users.add [user2]

#     contains control,
#       "<div>#{namify user1}</div>"
#       "<div>#{namify user2}</div>"
#       "<div>#{namify user3}</div>"

#     expect(control.rows).to.deep.equal [
#       namify user1
#       namify user2
#       namify user3
#     ]

#     # Remove element
#     users.remove user1

#     contains control,
#       "<div>#{namify user2}</div>"
#       "<div>#{namify user3}</div>"

#     expect(control.rows).to.deep.equal [
#       namify user2
#       namify user3
#     ]

#     # Reset elements
#     users.reset user4

#     contains control,
#       "<div>#{namify user4}</div>"

#     expect(control.rows).to.deep.equal [
#       namify user4
#     ]

#   it 'Table from element', ->
#     $('body').html """
#       <div>
#         <div>one</div>
#         <div>2</div>
#         <div></div>
#       </div>
#     """

#     $table = $('body > div')

#     control = oj.Table el:$table[0]
#     expect(oj.typeOf control).to.equal 'Table'
#     expect(control.rowCount).to.equal 3

#     expect(control.row(0)).to.equal 'one'
#     expect(control.row(1)).to.equal '2'
#     expect(control.row(2)).to.not.exist

#     expect(control.rows).to.deep.equal ['one', '2', undefined]

