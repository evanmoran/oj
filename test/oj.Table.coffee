# oj.Table.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
Backbone = require 'backbone'
oj = require '../oj.js'

a1 = 'a1'
a2 = 'a2'
a3 = 'a3'
b1 = 'b1'
b2 = 'b2'
b3 = 'b3'
c1 = 'c1'
c2 = 'c2'
c3 = 'c3'
d1 = 'd1'
d2 = 'd2'
d3 = 'd3'
h1 = 'h1'
h2 = 'h2'
h3 = 'h3'
f1 = 'f1'
f2 = 'f2'
f3 = 'f3'

aRow = [a1,a2,a3]
bRow = [b1,b2,b3]
cRow = [c1,c2,c3]
dRow = [d1,d2,d3]
hRow = [h1,h2,h3]
fRow = [f1,f2,f3]
col1 = [a1,b1,c1]
col2 = [a2,b2,c2]
col3 = [a3,b3,c3]

user1 = id:1, name:'Alfred', strength: 11
user2 = id:2, name:'Batman', strength: 22
user3 = id:3, name:'Catwoman', strength: 33
user4 = id:4, name:'Gordan', strength: 44
user5 = id:5, name:'Poison Ivy', strength: 55
users3 = [user1,user2,user3]
users4 = [user1,user2,user3,user4]
users5 = [user1,user2,user3,user4,user5]

class UserModel extends Backbone.Model

userModel1 = new UserModel user1
userModel2 = new UserModel user2
userModel3 = new UserModel user3
userModel4 = new UserModel user4
userModel5 = new UserModel user5
userModels3 = [userModel1,userModel2,userModel3]
userModels4 = [userModel1,userModel2,userModel3,userModel4]
userModels5 = [userModel1,userModel2,userModel3,userModel4,userModel5]

class UserCollection extends Backbone.Collection
  model: UserModel
  comparator: (m) -> m.get 'name'

contains = (control, args...) ->
  html = oj.toHTML control
  for arg in args
    expect(html).to.contain arg

doesNotContain = (control, args...) ->
  html = oj.toHTML control
  for arg in args
    expect(html).to.not.contain arg

jsonify = (any) ->
  if oj.isString(any) or oj.isNumber(any) or oj.isBoolean(any)
    '' + any
  else
    JSON.stringify any

describe 'oj.Table', ->

  beforeEach ->
    $('body').html ''

  it 'exists', ->
    expect(oj.Table).to.be.a 'function'

  it 'construct default', ->
    control = oj.Table()
    expect(oj.isOJ control).to.equal true
    expect(control.typeName).to.equal 'Table'
    expect(control.rowCount).to.equal 0
    expect(control.columnCount).to.equal 0
    expect(control.rows).to.deep.equal []

  it 'construct with id', ->
    id = 'my-id'
    control = oj.Table id:id
    expect(control.rowCount).to.equal 0
    expect(control.columnCount).to.equal 0
    expect(control.id).to.equal id
    expect(control.attributes.id).to.equal id

  it 'construct with name', ->
    name = 'my-name'
    control = oj.Table name:name
    expect(control.rowCount).to.equal 0
    expect(control.columnCount).to.equal 0
    expect(control.name).to.not.exist
    expect(control.attributes.name).to.equal name

  it 'construct with invalid argument', ->
    expect(-> oj.Table 1).to.throw(Error)

  it 'construct with one argument', ->
    control = oj.Table [1]
    expect(control.typeName).to.equal 'Table'
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
    expect(control.typeName).to.equal 'Table'
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


  it 'removeRow, addRow', ->
    control = oj.Table aRow, bRow, cRow
    expect(control.rowCount).to.equal 3
    expect(control.columnCount).to.equal 3
    expect(control.typeName).to.equal 'Table'
    expect(control.rows).to.deep.equal [aRow, bRow, cRow]

    r = control.removeRow(1)
    expect(r).to.deep.equal bRow
    expect(control.rows).to.deep.equal [aRow,cRow]

    r = control.removeRow(1)
    expect(r).to.deep.equal cRow
    expect(control.rows).to.deep.equal [aRow]

    r = control.removeRow(0)
    expect(r).to.deep.equal aRow
    expect(control.rows).to.deep.equal []

    expect(-> control.removeRow(1)).to.throw Error
    expect(-> control.addRow(aRow,4)).to.throw Error

    # add empty
    control.addRow(0,bRow)
    expect(control.rows).to.deep.equal [bRow]

    # add last
    control.addRow(1,cRow)
    expect(control.rows).to.deep.equal [bRow, cRow]

    # add first
    control.addRow(0,aRow)
    expect(control.rows).to.deep.equal [aRow, bRow, cRow]

    # add middle
    control.addRow(1,dRow)
    expect(control.rows).to.deep.equal [aRow, dRow, bRow, cRow]

    # add not enough args
    expect(-> control.addRow(1)).to.throw Error

    # add invalid args
    expect(-> control.addRow(100,dRow)).to.throw Error

  it 'removeRow, addRow (w/default indexes)', ->
    control = oj.Table aRow, bRow, cRow
    expect(control.rowCount).to.equal 3
    expect(control.columnCount).to.equal 3
    expect(control.typeName).to.equal 'Table'
    expect(control.rows).to.deep.equal [aRow, bRow, cRow]

    r = control.removeRow()
    expect(r).to.deep.equal cRow
    expect(control.rows).to.deep.equal [aRow, bRow]

    r = control.removeRow()
    expect(r).to.deep.equal bRow
    expect(control.rows).to.deep.equal [aRow]

    r = control.removeRow()
    expect(r).to.deep.equal aRow
    expect(control.rows).to.deep.equal []

    expect(-> control.removeRow()).to.throw Error
    expect(-> control.addRow(1,aRow)).to.throw Error

    # add empty
    control.addRow(bRow)
    expect(control.rows).to.deep.equal [bRow]

    # add last
    control.addRow(cRow)
    expect(control.rows).to.deep.equal [bRow, cRow]

    # add first
    control.addRow(aRow)
    expect(control.rows).to.deep.equal [bRow, cRow, aRow]

    # add middle
    control.addRow(dRow)
    expect(control.rows).to.deep.equal [bRow, cRow, aRow, dRow]

    # add something that isn't an array
    expect(-> control.addRow(1)).to.throw Error

    # add invalid args
    expect(-> control.addRow(100,dRow)).to.throw Error

  it 'shiftRow, unshiftRow', ->
    control = oj.Table aRow, bRow, cRow
    expect(control.rowCount).to.equal 3
    expect(control.typeName).to.equal 'Table'
    expect(control.rows).to.deep.equal [aRow, bRow, cRow]

    r = control.shiftRow()
    expect(r).to.deep.equal aRow
    expect(control.rows).to.deep.equal [bRow, cRow]

    r = control.shiftRow()
    expect(r).to.deep.equal bRow
    expect(control.rows).to.deep.equal [cRow]

    r = control.shiftRow()
    expect(r).to.deep.equal cRow
    expect(control.rows).to.deep.equal []

    expect(-> control.shiftRow()).to.throw Error
    control.unshiftRow(aRow)
    expect(control.rows).to.deep.equal [aRow]

    control.unshiftRow(bRow)
    expect(control.rows).to.deep.equal [bRow, aRow]

  it 'popRow, pushRow', ->
    control = oj.Table aRow,bRow,cRow
    expect(control.rowCount).to.equal 3
    expect(control.typeName).to.equal 'Table'
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    r = control.popRow()
    expect(r).to.deep.equal cRow
    expect(control.rows).to.deep.equal [aRow,bRow]

    r = control.popRow()
    expect(r).to.deep.equal bRow
    expect(control.rows).to.deep.equal [aRow]

    r = control.popRow()
    expect(r).to.deep.equal aRow
    expect(control.rows).to.deep.equal []

    expect(-> control.popRow()).to.throw Error
    control.pushRow(aRow)
    expect(control.rows).to.deep.equal [aRow]

    control.pushRow(bRow)
    expect(control.rows).to.deep.equal [aRow, bRow]

  it 'moveRow', ->
    control = oj.Table aRow,bRow,cRow
    expect(control.rowCount).to.equal 3
    expect(control.typeName).to.equal 'Table'
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    # Move same position
    control.moveRow(0,0)
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    # Move up one
    control.moveRow(0,1)
    expect(control.rows).to.deep.equal [bRow,aRow,cRow]

    # Move to front / down one
    control.moveRow(1,0)
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    # Move from beginning to end
    control.moveRow(0,2)
    expect(control.rows).to.deep.equal [bRow,cRow,aRow]

    # Move from end to beginning
    control.moveRow(-1,0)
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    # Move to invalid
    expect(-> control.moveRow(0,100)).to.throw Error

    # Move not enough args
    expect(-> control.moveRow(0)).to.throw Error


  it 'swapRow', ->
    control = oj.Table aRow,bRow,cRow
    expect(control.rowCount).to.equal 3
    expect(control.typeName).to.equal 'Table'
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    # Swap same position
    control.swapRow(0,0)
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    # Swap up one
    control.swapRow(0,1)
    expect(control.rows).to.deep.equal [bRow,aRow,cRow]

    # Swap to front / down one
    control.swapRow(1,0)
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    # Swap from beginning to end
    control.swapRow(0,2)
    expect(control.rows).to.deep.equal [cRow,bRow,aRow]

    # Swap from end to beginning
    control.swapRow(-1,0)
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    # Swap to invalid
    expect(-> control.swapRow(0,100)).to.throw Error

    # Swap not enough args
    expect(-> control.swapRow(0)).to.throw Error

  it 'header empty', ->
    control = oj.Table header:[]
    expect(control.rowCount).to.equal 0
    expect(control.columnCount).to.equal 0

    expect(control.header).to.deep.equal []

    contains control,
      'class="oj-Table"'
      '<table'
      '</table>'

    doesNotContain control,
      '<thead'
      '<tr'
      '<th'
      '</tr>'
      '</thead>'

  it 'header', ->
    control = oj.Table header:aRow
    expect(control.rowCount).to.equal 0
    expect(control.columnCount).to.equal 3 # should include columns by header,body,or footer

    expect(control.header).to.deep.equal aRow

    contains control,
      'class="oj-Table"'
      '<table'
      '<thead'
      '<tr'
      '<th>a1</th>'
      '<th>a2</th>'
      '<th>a3</th>'
      '</tr>'
      '</thead>'
      '</table>'

    doesNotContain control,
      '<tbody'
      '</tbody>'

  it 'footer empty', ->
    control = oj.Table footer:[]
    expect(control.rowCount).to.equal 0
    expect(control.columnCount).to.equal 0

    expect(control.footer).to.deep.equal []

    contains control,
      'class="oj-Table"'
      '<table'
      '</table>'

    doesNotContain control,
      '<tfoot'
      '<tr'
      '<th'
      '</tr>'
      '</tfoot>'

  it 'footer', ->
    control = oj.Table footer:aRow
    expect(control.rowCount).to.equal 0
    expect(control.columnCount).to.equal 3 # should include columns by header,body,or footer
    expect(control.header).to.deep.equal []
    expect(control.footer).to.deep.equal aRow

    contains control,
      'class="oj-Table"'
      '<table'
      '<tfoot'
      '<tr'
      '<td>a1</td>'
      '<td>a2</td>'
      '<td>a3</td>'
      '</tr>'
      '</tfoot>'
      '</table>'

    doesNotContain control,
      '<tbody'
      '</tbody>'
      '<thead'
      '</thead>'

  it 'header, footer, body', ->
    control = oj.Table header:hRow, aRow, bRow, cRow, footer:fRow
    expect(control.rowCount).to.equal 3
    expect(control.columnCount).to.equal 3
    expect(control.header).to.deep.equal hRow
    expect(control.footer).to.deep.equal fRow
    expect(control.rows).to.deep.equal [aRow,bRow,cRow]

    contains control,
      'class="oj-Table"'
      '<table'

      '<tfoot'
      '</tfoot>'
      '<tbody'
      '</tbody>'
      '<thead'
      '</thead>'

      '<tr'
      '</tr>'

      '<th>h1</th>'
      '<th>h2</th>'
      '<th>h3</th>'

      '<td>a1</td>'
      '<td>a2</td>'
      '<td>a3</td>'
      '<td>f1</td>'
      '<td>f2</td>'
      '<td>f3</td>'

      '</table>'

  it 'caption', ->
    caption = "caption"
    control = oj.Table caption:caption, aRow, bRow, cRow
    expect(control.header).to.deep.equal []
    expect(control.footer).to.deep.equal []
    expect(control.caption).to.equal caption

    contains control,
      'class="oj-Table"'
      '<table'
      '<caption>caption</caption>'

  it 'construct with list of objects for models (default each)', ->
    control = oj.Table models:users3

    expect(control.rowCount).to.equal 3
    expect(control.typeName).to.equal 'Table'
    expect(control.typeName).to.equal 'Table'

    contains control,
      "<td>#{user1.name}</td>"
      "<td>#{user2.name}</td>"
      "<td>#{user3.name}</td>"

    expect(control.rows).to.deep.equal [
      [user1.id, user1.name, user1.strength]
      [user2.id, user2.name, user2.strength]
      [user3.id, user3.name, user3.strength]
    ]

  it 'construct with list of backbone models (default each)', ->
    control = oj.Table models:userModels3

    expect(control.rowCount).to.equal 3
    expect(control.typeName).to.equal 'Table'
    expect(control.typeName).to.equal 'Table'

    contains control,
      "<td>#{user1.name}</td>"
      "<td>#{user2.name}</td>"
      "<td>#{user3.name}</td>"

    expect(control.rows).to.deep.equal [
      [user1.id, user1.name, user1.strength]
      [user2.id, user2.name, user2.strength]
      [user3.id, user3.name, user3.strength]
    ]

  it 'construct with backbone collection (default each)', ->

    users = new UserCollection [user3, user1]

    control = oj.Table models:users

    expect(control.rowCount).to.equal 2
    expect(control.typeName).to.equal 'Table'
    expect(control.typeName).to.equal 'Table'

    contains control,
      "<td>#{user1.name}</td>"
      "<td>#{user3.name}</td>"

    doesNotContain control,
      "<td>#{user2.name}</td>"

    expect(control.rows).to.deep.equal [
      [user1.id, user1.name, user1.strength]
      [user3.id, user3.name, user3.strength]
    ]

    # Change collection
    users.add [user2]

    expect(control.rowCount).to.equal 3

    contains control,
      "<td>#{user1.name}</td>"
      "<td>#{user2.name}</td>"
      "<td>#{user3.name}</td>"

    expect(control.rows).to.deep.equal [
      [user1.id, user1.name, user1.strength]
      [user2.id, user2.name, user2.strength]
      [user3.id, user3.name, user3.strength]
    ]
    users.remove user1

    expect(control.rowCount).to.equal 2

    contains control,
      "<td>#{user2.name}</td>"
      "<td>#{user3.name}</td>"

    doesNotContain control,
      "<td>#{user1.name}</td>"

    expect(control.rows).to.deep.equal [
      [user2.id, user2.name, user2.strength]
      [user3.id, user3.name, user3.strength]
    ]

    users.reset user4

    contains control,
      "<td>#{user4.name}</td>"

    doesNotContain control,
      "<td>#{user1.name}</td>"
      "<td>#{user2.name}</td>"
      "<td>#{user3.name}</td>"

    expect(control.rows).to.deep.equal [
      [user4.id, user4.name, user4.strength]
    ]

  it 'construct with backbone collection (manual each)', ->

    users = new UserCollection [user3, user1]

    control = oj.Table models:users, each: (model,td) ->
      td model.get('name')
      td model.get('strength')

    expect(control.rowCount).to.equal 2
    expect(control.typeName).to.equal 'Table'
    expect(control.typeName).to.equal 'Table'

    contains control,
      "<td>#{user1.name}</td>"
      "<td>#{user3.name}</td>"

    doesNotContain control,
      "<td>#{user2.name}</td>"

    expect(control.rows).to.deep.equal [
      [user1.name, user1.strength]
      [user3.name, user3.strength]
    ]

    # Change collection
    users.add [user2]

    expect(control.rowCount).to.equal 3

    contains control,
      "<td>#{user1.name}</td>"
      "<td>#{user2.name}</td>"
      "<td>#{user3.name}</td>"

    expect(control.rows).to.deep.equal [
      [user1.name, user1.strength]
      [user2.name, user2.strength]
      [user3.name, user3.strength]
    ]
    users.remove user1

    expect(control.rowCount).to.equal 2

    contains control,
      "<td>#{user2.name}</td>"
      "<td>#{user3.name}</td>"

    doesNotContain control,
      "<td>#{user1.name}</td>"

    expect(control.rows).to.deep.equal [
      [user2.name, user2.strength]
      [user3.name, user3.strength]
    ]

    users.reset user4

    contains control,
      "<td>#{user4.name}</td>"

    doesNotContain control,
      "<td>#{user1.name}</td>"
      "<td>#{user2.name}</td>"
      "<td>#{user3.name}</td>"

    expect(control.rows).to.deep.equal [
      [user4.name, user4.strength]
    ]

  it 'theming', ->
    theme1 = 'charmed'
    theme2 = 'strange'

    oj.Table.theme(theme1, {
      'tr:not(:last-child)':{
        borderBottom:'1px solid orange'
      }
    })
    oj.Table.theme(theme2, {
      'tr:nth-child(even)':{
        backgroundColor:'orange'
      }
    })
    expect(oj.Table.themes).to.deep.equal ['charmed', 'strange']

    # create table with theme
    class1 = 'my-class'
    control = oj.Table c:class1, aRow, bRow, cRow
    expect(control.hasClass class1).to.equal true

    control = oj.Table themes:[theme1], aRow, bRow, cRow
    expect(control.hasTheme theme1).to.equal true
    expect(control.hasTheme theme2).to.equal false
    expect(control.themes).to.deep.equal [theme1]

    # Accept single theme as well as list
    control = oj.Table themes:theme1, aRow, bRow, cRow
    expect(control.hasTheme theme1).to.equal true
    expect(control.hasTheme theme2).to.equal false
    expect(control.themes).to.deep.equal [theme1]

    # Accept multiple themes
    control = oj.Table themes:[theme1,theme2], aRow, bRow, cRow
    expect(control.hasTheme theme1).to.equal true
    expect(control.hasTheme theme2).to.equal true
    expect(control.themes).to.deep.equal [theme1,theme2]

    # Add / Remove themes test
    control = oj.Table themes:[theme1,theme2], aRow, bRow, cRow
    control.removeTheme theme1
    expect(control.themes).to.deep.equal [theme2]

    # Remove theme that doesn't exist des nothing
    control.removeTheme theme1
    expect(control.themes).to.deep.equal [theme2]

    control.removeTheme theme2
    expect(control.themes).to.deep.equal []

    # Add themes
    control.addTheme theme2
    expect(control.themes).to.deep.equal [theme2]

    # Adding theme twice doesn't change the result
    control.addTheme theme2
    expect(control.themes).to.deep.equal [theme2]

    # Multiple themes can be added
    control.addTheme theme1
    expect(control.themes).to.deep.equal [theme2, theme1]

    # Clearing themes works
    control.clearThemes()
    expect(control.themes).to.deep.equal []

    # Add themes all at once
    control.themes = [theme2, theme1]
    expect(control.themes).to.deep.equal [theme2, theme1]

    # Overwrite themes all at once
    control.themes = [theme2]
    expect(control.themes).to.deep.equal [theme2]
