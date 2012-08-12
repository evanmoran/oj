oj - The big gulp of templating engines

Templates: html, css, and javascript simultaneously

### oj.tag

    oj.tag name [attributes], [content, content, ...]
        name: String defining the tag name to serialize
              If name starts with an '_' it is serialized verbatum. Otherwise it is constructed as an full OJ object and attributes are passed to the constructor
        attributes: Object defining attributes to serialize into the tag
        content: recursively defined ojml


    oj.tag 'div', {},


Goals of OJ

* Create an object representation of HTML and CSS.
* Create a JSON representation of HTML and CSS.
* Create a method representation of HTML and CSS.
* 100% shared client and server code
* The dream of Node.js is fulfilled.
* Express 3 support
* Integrates with jQuery for event triggering
* Integrates into Backbone for object construction

Functions
---------





OJ Objects
------------------------------------------------------------------



### oj.Table

    oj.Table options, row1, row2, ...

    options           Object to configure Table
      header          Array option to set header at once
      footer          Array option to set footer at once
      rows            Array of arrays option to set all rows at once

    row1, ...         Array of elements defining row1, row2, etc.
                      Rows also accept functions that return arrays

Example:

    table = oj.Table                         # oj.Table is equivalent to new oj.Table
      c: 'c123'                              # c is an alias for 'class'
      id: 'id123'
      header: ['h1', 'h2', 'h3']
      footer: ['f1', 'f2', 'f3']
      [
        [1,2,3]
        [4,5,6]
      ]

    table.html()
      # <table class='c123', id='id123'>
      #   <thead>
      #     <th> <td>h1</td> <td>h2</td> <td>h3</td> </th>
      #   </thead>
      #   <tbody>
      #     <tr> <td>1</td> <td>2</td> <td>3</td> </tr>
      #     <tr> <td>4</td> <td>5</td> <td>6</td> </tr>
      #   </tbody
      #   <tfoot>
      #     <th> <td>f1</td> <td>f2</td> <td>f3</td> </th>
      #   </tfoot>
      # </table>

    table.addRow [7,8,9]                # add a row to the end
    table.removeRow 1                   # remove row index 1

    table.id = null                     # clear the id
    table.header = null                 # clear the header
    table.footer = null                 # clear the footer

    table.html()
      # =>
      # <table class='c123'>
      #   <tbody>
      #     <tr> <td>1</td> <td>2</td> <td>3</td> </tr>
      #     <tr> <td>4</td> <td>5</td> <td>6</td> </tr>
      #     <tr> <td>7</td> <td>8</td> <td>9</td> </tr>
      #   </tbody
      # </table>

### oj.List

    oj.List options, item1, item2, ...

    options           Object that configures List and common options

      ordered:        Boolean option that indicates if list is ordered.
                      Defaults to false (bullet list), true means number list

    style options
      style:          Inline style
      css:            css generated from selector

    behavior options

`List` has two specializations for convenience:

1. `BulletList` is the same as: `List ordered: false`

2. `NumberList` is the same as: `List ordered: true`

Example:

    list = oj.List class: 'c123', ordered: true
      'a'
      'b'
      'c'

    list.html()           # =>  <ol class='c123'><li>a</li><li>b</li><li>c</li></ol>
    list.ordered = false
    list.html()           # =>  <ul class='c123'><li>a</li><li>b</li><li>c</li></ul>


### oj.Link
### oj.Image
### oj.CheckBox
### oj.ListBox
### oj.TextBox
### oj.Form

OJ Custom Objects
------------------------------------------------------------------

OJ defines smart structured objects to help you abstract your website structure. These objects can do a great deal for normal views, but sometimes you want to make your own smart objects. These methods will help you create OJ compatible objects for yourself.

_Hint:_ Generally we have found smaller building blocks are are better. So don't create an OJ object called `ProfilePage`. It would be better to create separate controls for displaying `UserPicture`, `UserLink`, `SettingsList`, and then in the `ProfilePage` view use these parts to build the page up from the model.

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

    {oj: 'table', ...}              # Lowercase means tag:             <table>...</table>
    {oj: 'Table', ...}              # Uppercase means an oj object:     new oj.Table(...)

Since OJ objects can all serialize into OJML and HTML these may be nested at will:

    {oj: 'List', ordered: false, items: [                # List
      {oj: 'a', href: 'user/profile', _: 'Evan'},        #   <link to Evan's profile>
      {oj: 'Image', url: 'evan.png'}                     #   <Evan's picture>
    ]}

This is equivalent to:

    oj.List ordered: false,
      (oj.a href: 'user/profile', 'Evan')
      (oj.Image url: 'evan.png')

The purpose is not to make the most readable syntax (though it's not bad!). The goal is to make a very clear abstraction layer to allow serialization and a useful intermediate layer for templating.

Example: div tag

    div 1                       <div>1</div>                  {oj:'div', _:1}

Example: div with id

    div id:'one', 1             <div id='one'>1</div>         {oj: 'div', id:'one', _:1}

Example: Nested divs with class

    div c='nested', [           <div class='nested'>          {oj: 'div', c:'nested', _:[
      div 1                       <div>1</div>                  {oj: 'div', _:1},
      div 2                       <div>2</div>                  {oj: 'div', _:2},
      div 3                       <div>3</div>                  {oj: 'div', _:3},
    ]                           </div>                        ]}

Example: Complex Nested divs

    div [                       <div>                         {oj: 'div', _:[
      div 1                       <div>1</div>                  {oj: 'div', _:1},
      div [                       <div>                         {oj: 'div', _:[
        div 2                       <div>2</div>                  {oj: 'div', _:2},
        div 3                       <div>3</div>                  {oj: 'div', _:3}
      ]                           </div>                        ]}
    ]                           </div>                        ]}

Example: ul tag

    ul [                        <ul>                          {oj: 'ul', _:[
      li 1                        <li>1</li                     {oj: 'li', _:1},
      li 2                        <li>2</li>                    {oj: 'li', _:2},
      li 3                        <li>3</li>                    {oj: 'li', _:3}
    ]                           </ul>                         ]}

Example: List

    List [1,2,3]                <ul>                          {oj: 'ul', _:[
                                  <li>1</li>                    {oj: 'li', _:1},
                                  <li>2</li>                    {oj: 'li', _:2},
                                  <li>3</li>                    {oj: 'li', _:3}
                                </ul>                         ]}

Example: table tag

    table [                     <table>
      tbody [                     <tbody>
        tr [(td 1), (td 2)]         <tr> <td>1</td> <td>2</td> </tr>
        tr [(td 3), (td 4)]         <tr> <td>3</td> <td>4</td> </tr>
      ]                           </tbody>
    ]                           </table>


Example: Table

    Table [[1,2],[3,4]]         <table>
                                  <tbody>
                                    <tr> <td>1</td> <td>2</td> </tr>
                                    <tr> <td>3</td> <td>4</td> </tr>
                                  </tbody>
                                </table>

