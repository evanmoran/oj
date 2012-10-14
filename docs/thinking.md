



div = oj.div

oj.div ->
  oj.div 1
  oj.div 2


@div =>
  @Table =>
  @div =>


oj.div(
  oj.div(1),
  oj.div(2)
)

[ 'div', foo:1, [
  ['div']
  ]
]











$("body").jsml(
  ,"<p>Hello World</p>"   // text works
  ,["div", {id:"id-345"}                      // tag and attribute definition
    ,"String"                         // string type interperated as html
    ,"<b>String with html</b><br>"                // string with html interperate directly
    ,42                             // number type is converted to string
    ,true                           // boolean type is converted to string
    ,null                           // null type is ignored
    ,undefined                          // undefined type is ignored
    ,$("<p>Jquery object</p>")                  // jquery objects are converted to html
  ]
  ,["table", {id:"id-346", "class":"cls-myclass"}
    ,["tbody"                         // attributes are optional
      ,["tr",
        ,["td", {style:"background-color:orange"}     // style as string
          ,"Column 1"
        ]
        ,["td", {style":{"background-color":"lightblue"}} // style as object
          ,"Column 2 with link: "
          ,["a", {href:"http://www.example.com"}
             ,"example.com"
          ]
        ]
      ]
    ]
  ]
  ,["div", {class:["cls-1", "cls-2"]}               // class can be set with list of strings
    ,"Div with multiple classes"
  ]
  ,["div", {meta:{name:"Evan", age:27}}               // meta attributes are jsoned and set as string
    ,"Div with meta defined"
  ]
);

$("body").jsml [
  "<p>Hello World</p>"
  ['p', 'Hello World']


oj.div 'value' -> ['div', 'value']

#77 coffeescript: no magic
["div", id:"id-345",
  ['div', 'value']
  ['div',
    ['div', 'value']
  ]
]

oj.interpret
  ['Table',
    [1,2],
    [1,2]
  ]




["div", id:"id-345",
  ['div', 'value']
  oj.AutoTable users,
    header: ->
      ['name', 'phonenumber']
    (u) ->
      [u.name, u.phonenumber]
]



["div", id:"id-345",
  ['div', 'value']
  oj.Table users,
    header: ->
      ['name', 'phonenumber']
    model: users
    modelRow: (user) ->
      [oj.div(u.name), u.phonenumber]
]

userRow = (user) ->

Table [
  [   , foo:bar]
  []
  []
]


div ->   # push global
  div ->  # push global2
    div 1 # add {div, _:1} to global 2
  # restore global
# restore null







oj.Table
  header: ->
    ['User', 'Description']
  model: users
  modelRow: (user) ->
    [oj.Image(url: user.thumbnail), oj.div(user.description), {meta: user.id}]
  footer: ->
    ['Footers', 'Why?']

oj.AutoTable users, (user) -> [
  oj.CheckBox label: user.name
  oj.Image url: user.thumbnail
  oj.div user.description
  {meta: user.id}
]

oj.AutoList list, (item) ->
  item.name

oj.ul ->
  for name in list
    oj.li name

oj.ul ->
  _.map list, (item) -> oj.li item.name


users.Table (user) -> [
  oj.CheckBox label: user.name
  oj.Image url: user.thumbnail
  oj.div user.description
  {meta: user.id}
]





Table [
  [1,2]
  [1,2]
]

{oj:'Table', _:[
  [1,2],
  [1,2]
]}

#80
["div", {id:"id-345"},
  ['div', 'value'],
  ['div',
    ['div', 'value']
  ]
]

#64 javascript: no magic
div({id:'id-345'},
  div('value'),
  div(
    div('value')
  )
)

#59 (requires magic templating and stacking)
div id: 'id-345', ->
  div 'value'
  div ->
    div 'value'

#63 coffee-script no magic
@div id: 'id-345', =>
  @div 'value'
  @div =>
    @div 'value'

#71 (requires magic stacking)
oj.div id: 'id-345', ->
  oj.div 'value'
  oj.div ->
    oj.div 'value'

#75 No magic
oj.div id: 'id-345', [
  oj.div 'value'
  oj.div [
    oj.div 'value'
  ]
]

#92 OJML
{oj:"div", id:"id-345", _:[
  {oj:'div', _:'value'}
  {oj:'div', _:{oj:'div', _:'value'}}
]}

  ["table",
    ["tbody",
      ["tr",
        ["td", {style:"background-color:orange"}     // style as string
          ,"Column 1"
        ]
        ["td", {style":{"background-color":"lightblue"}} // style as object
          ,"Column 2 with link: "
          ,["a", {href:"http://www.example.com"}
             ,"example.com"
          ]
        ]
      ]
    ]
  ]
  ,["div", {class:["cls-1", "cls-2"]}               // class can be set with list of strings
    ,"Div with multiple classes"
  ]
  ,["div", {meta:{name:"Evan", age:27}}               // meta attributes are jsoned and set as string
    ,"Div with meta defined"
  ]
]

