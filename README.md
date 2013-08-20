
oj
================================================================================

Unified web templating for the people. *Thirsty people.*

[ojjs.org/docs](http://ojjs.org/docs)

[ojjs.org/learn](http://ojjs.org/learn)

[ojjs.org/download](http://ojjs.org/download)


<!--

OJML
------------------------------------------------------------------

OJML is the JSON representation of OJ. For most of OJ this representation is abstracted away -- you won't need to call these methods directly. For those people who are curious, or are writing mixins to OJ, knowledge of this format is useful.

Features of OJML

* A serialization form of OJ
* Can be generated server or client side.
* Can awaken OJ objects from OJML
* Templating methods use OJML as a middle-step so both HTML and CSS templating functions
can use the same precomputed structure.

### Basics of OJML

All OJML is represented as an object with potentially large amounts of nesting. Each objects has an `oj` attribute describing the type of structure it is:

    ['table', ...]              # Lowercase means tag:             <table>...</table>
    ['Table', ...]              # Uppercase means an oj object:     new oj.Table(...)

Since OJ objects can all serialize into OJML and HTML these may be nested at will:

    ['List', ordered: false,                         # List
      ['a', href: 'user/profile', _: 'Evan']         #   <link to Evan's profile>
      ['Image', url: 'evan.png']                     #   <Evan's picture>
    ]

This is equivalent to:

    oj.List ordered: false,
      (oj.a href: 'user/profile', 'Evan')
      (oj.Image url: 'evan.png')

The purpose is not to make the most readable syntax (though it's not bad!). The goal is to make a very clear abstraction layer to allow serialization and a useful intermediate layer for templating.

Example: div tag

    div 1                       <div>1</div>                  ['div', 1]

Example: div with id

    div id:'one', 1             <div id='one'>1</div>         ['div', id:'one', 1]

Example: Nested divs with class

    div c='nested', [           <div class='nested'>          ['div', c:'nested',
      div 1                       <div>1</div>                  ['div', 1]
      div 2                       <div>2</div>                  ['div', 2]
      div 3                       <div>3</div>                  ['div', 3]
    ]                           </div>                        ]

Example: Complex Nested divs

    div ->                      <div>                         ['div',
      div 1                       <div>1</div>                  ['div', 1]
      div ->                      <div>                         ['div',
        div 2                       <div>2</div>                  ['div', 2]
        div 3                       <div>3</div>                  ['div', 3]
                                 </div>                         ]
                                </div>                        ]

    div (div 1),                <div>                         ['div',
      div (div 2),                <div>1</div>                  ['div', 1]
        (div 3)                   <div>                         ['div',
                                    <div>2</div>                  ['div', 2]
                                    <div>3</div>                  ['div', 3]
                                  </div>                        ]
                                </div>                        ]

Javascript 1

    div(function(){
      div(1)
      div(function(){
        div(2)
        div(3)
      })
    })

Javascript 2

    div([
      div(1),
      div([
        div(2),
        div(3)
      ])
    ])

Javascript 3

    div( {id:1}
      div(1),
      div(
        div(2),
        div(3)
      )
    )

Example: ul tag

    ul ->                       <ul>                          ['ul',
      li 1                        <li>1</li                     ['li', 1],
      li 2                        <li>2</li>                    ['li', 2],
      li 3                        <li>3</li>                    ['li', 3]
                                </ul>                         ]

Example: List

    List                        <ul>                          ['ul',
      1                           <li>1</li>                    ['li', 1],
      2                           <li>2</li>                    ['li', 2],
      3                           <li>3</li>                    ['li', 3]
                                </ul>                         ]

Example: table tag

    table ->                    <table>                                 ['table',
      tbody ->                    <tbody>                                 ['tbody',
        tr (td 1), (td 2)           <tr> <td>1</td> <td>2</td> </tr>        ['tr', ['td' 1], ['td', 2]]
        tr (td 3), (td 4)           <tr> <td>3</td> <td>4</td> </tr>        ['tr', ['td' 3], ['td', 4]]
                                  </tbody>                                ]
                                </table>                                ]

Example: Table

    Table                       <table>
      [1,2]                         <tbody>
      [3,4]                         <tr> <td>1</td> <td>2</td> </tr>
                                    <tr> <td>3</td> <td>4</td> </tr>
                                  </tbody>
                                </table>
 -->