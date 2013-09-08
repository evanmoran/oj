# test/oj.compile.coffee
#
# Test oj.compile method for generating html, css, javascript

path = require 'path'
fs = require 'fs'
async = require 'async'

oj = require '../generated/oj.js'

cssTest = (ojml, css, options) ->
  options = _.defaults {}, options,
    html:true
    css:true
    styles:false
    dom:false
    minify:true

  r = oj.compile options, ojml
  if not (options.css == false)
    expect(r.css).to.be.a 'string'
    expect(r.css).to.equal css
  else
    expect(r.css).to.not.exist

stylesTest = (ojml, styles, options) ->
  options = _.defaults {}, options,
    html:true
    cssMap:true
    dom:false
    minify:true

  r = oj.compile options, ojml
  expect(r.cssMap).to.be.an 'object'

  stylesHTML = ""
  for plugin, mediaMap of r.cssMap
    stylesHTML += oj._styleTagFromMediaObject plugin, mediaMap, options

  expect(stylesHTML).to.equal styles

cssTestException = (ojml, exception, options = {}) ->
  expect(-> oj.compile options, ojml).to.throw exception

_clear = ($el = $('body')) -> $el.html ''

describe 'oj.compile.css', ->
  beforeEach ->
    _clear $('body')

  it 'exists', ->
    expect(oj.compile).to.exist
    oj.compile.should.be.a 'function'

  it 'span without css', ->
    ojml = oj.span 'test'
    cssTest ojml, ''

  it 'divs without css', ->
    ojml = oj.div ->
      oj.div 'test'
    cssTest ojml, ''

  it 'one rule', ->
    ojml = oj.css
      body:
        color: 'red'
    cssTest ojml, 'body{color:red}'
    cssTest ojml, 'body {\n\tcolor:red;\n}\n', minify:false

  it 'two rules', ->
    ojml = oj.css
      body:
        color: 'red'
      '.selector':
        border: '1px solid black'

    cssTest ojml, 'body{color:red}.selector{border:1px solid black}'
    cssTest ojml, 'body {\n\tcolor:red;\n}\n.selector {\n\tborder:1px solid black;\n}\n', minify:false

  # TODO: This can only work if css minifier is really smart. Not sure if
  # there is a node minifier that supports this...
  it 'merged rules'
    # ojml = oj.css
    #   '.c1':
    #     color: 'red'
    #   '.c2':
    #     color: 'red'
    # cssTest ojml, '.c1,.c2{color:red}'
    # cssTest ojml, '.c1,\n.c2 {\n\tcolor:red;\n}\n.c2 {\n\tcolor:red;\n}\n',minify:false

  it 'multiple intersecting definitions', ->
    ojml = ->
      oj.css
        p:
            color:'red'
      oj.css
        p:
            fontSize:'10px'
      oj.css
        '@media monitor':
          p:
            backgroundColor:'orange'

    cssTest ojml, 'p{background-color:orange;color:red;font-size:10px}'
    cssTest ojml, 'p {\n\tbackground-color:orange;\n\tcolor:red;\n\tfont-size:10px;\n}\n', minify:false

  it 'single comma seperated definition', ->
    ojml = oj.css
      '.c1,.c2':
          color:'red'

    cssTest ojml, '.c1,.c2{color:red}'
    cssTest ojml, '.c1,\n.c2 {\n\tcolor:red;\n}\n', minify:false

  it 'single nested definition', ->
    ojml = oj.css
      '.c1':
        '.c2':
          color:'red'

    cssTest ojml, '.c1 .c2{color:red}'
    cssTest ojml, '.c1 .c2 {\n\tcolor:red;\n}\n', minify:false

  it 'multiple nested definitions', ->
    ojml = oj.css
      'div':
        '.c1':
          color:'red'
        '#id1':
          color:'blue'
          '.c2':
            color:'yellow'

    cssTest ojml, 'div .c1{color:red}div #id1{color:blue}div #id1 .c2{color:yellow}'
    cssTest ojml, 'div .c1 {\n\tcolor:red;\n}\ndiv #id1 {\n\tcolor:blue;\n}\ndiv #id1 .c2 {\n\tcolor:yellow;\n}\n', minify:false

  it 'single nested definitions with &', ->
    ojml = oj.css
      '.c1':
        '&.red':
          color:'red'

    cssTest ojml, '.c1.red{color:red}'
    cssTest ojml, '.c1.red {\n\tcolor:red;\n}\n', minify:false

  it 'single nested definitions with &:hover', ->
    ojml = oj.css
      '.c1':
        '.c2':
          '&:hover':
            color:'red'

    cssTest ojml, '.c1 .c2:hover{color:red}'
    cssTest ojml, '.c1 .c2:hover {\n\tcolor:red;\n}\n', minify:false


  it 'multiple nested definitions with & at front', ->
    ojml = oj.css
      'div':
        '&.c1':
          color:'red'
        '&#id1':
          color:'blue'
          '&.c2':
            color:'yellow'
    cssTest ojml, 'div.c1{color:red}div#id1{color:blue}div#id1.c2{color:yellow}'
    cssTest ojml, 'div.c1 {\n\tcolor:red;\n}\ndiv#id1 {\n\tcolor:blue;\n}\ndiv#id1.c2 {\n\tcolor:yellow;\n}\n', minify:false

  it 'multiple nested definitions with & at end', ->
    ojml = oj.css
      'div':
        '.c1 &':
          color:'red'
        '&#id1':
          color:'blue'
          '.c2 &':
            color:'yellow'
    cssTest ojml, '.c1 div{color:red}div#id1{color:blue}.c2 div#id1{color:yellow}'
    cssTest ojml, '.c1 div {\n\tcolor:red;\n}\ndiv#id1 {\n\tcolor:blue;\n}\n.c2 div#id1 {\n\tcolor:yellow;\n}\n', minify:false

  it 'nested definitions with comma seperation', ->
    ojml = oj.css
      'b, a':
        '.c1':
          color:'red'
          '&.c2':
            color:'yellow'
          '.c3 &':
            color:'purple'
    cssTest ojml, 'a .c1,b .c1{color:red}a .c1.c2,b .c1.c2{color:yellow}.c3 a .c1,.c3 b .c1{color:purple}'
    cssTest ojml, 'a .c1,\nb .c1 {\n\tcolor:red;\n}\na .c1.c2,\nb .c1.c2 {\n\tcolor:yellow;\n}\n.c3 a .c1,\n.c3 b .c1 {\n\tcolor:purple;\n}\n', minify:false

  it 'top level @media query', ->

    ojml = oj.css
      '@media all':
        '.c1':
          color:'red'

    cssTest ojml, '@media all{.c1{color:red}}'

  it 'top level @media query with complex selectors', ->
    ojml = oj.css
      '@media screen (min-width: 768px) and (max-width: 979px)':
        '.c1':
          color:'red'
          '&.c2':
            color:'orange'
            '.c3':
              color:'purple'

    cssTest ojml, '@media screen (min-width: 768px) and (max-width: 979px){.c1{color:red}.c1.c2{color:orange}.c1.c2 .c3{color:purple}}'
    cssTest ojml, '@media screen (min-width: 768px) and (max-width: 979px) {\n\t.c1 {\n\t\tcolor:red;\n\t}\n\t.c1.c2 {\n\t\tcolor:orange;\n\t}\n\t.c1.c2 .c3 {\n\t\tcolor:purple;\n\t}\n}\n', minify:false

  it 'nested @media query', ->

    ojml = oj.css
      '.c1':
        color:'blue'
        '@media print':
          color:'black'

    cssTest ojml, '.c1{color:blue}@media print{.c1{color:black}}'
    cssTest ojml, '.c1 {\n\tcolor:blue;\n}\n@media print {\n\t.c1 {\n\t\tcolor:black;\n\t}\n}\n', minify:false

  it 'complex nested @media query with complex selectors', ->
    ojml = oj.css
      '.c0':
        color:'blue'
        '@media screen (min-width: 100px)':
          '.c1':
            color:'red'
            '@media screen (min-width: 200px)':
              color:'orange'

    cssTest ojml, '.c0{color:blue}@media screen (min-width: 100px){.c0 .c1{color:red}}@media screen (min-width: 100px) and screen (min-width: 200px){.c0 .c1{color:orange}}'
    cssTest ojml, '.c0 {\n\tcolor:blue;\n}\n@media screen (min-width: 100px) {\n\t.c0 .c1 {\n\t\tcolor:red;\n\t}\n}\n@media screen (min-width: 100px) and screen (min-width: 200px) {\n\t.c0 .c1 {\n\t\tcolor:orange;\n\t}\n}\n', minify:false

  it 'complex nested @media query with complex selectors', ->
    ojml = oj.css
      '.c0':
        color:'blue'
        '@media screen (min-width: 100px)':
          '.c1':
            color:'red'
            '@media screen (min-width: 200px)':
              color:'orange'
              '&.c2':
                color:'purple'
            '@media screen (min-width: 300px)':
              '.c3':
                color:'yellow'

    cssTest ojml, '.c0{color:blue}@media screen (min-width: 100px){.c0 .c1{color:red}}@media screen (min-width: 100px) and screen (min-width: 200px){.c0 .c1{color:orange}.c0 .c1.c2{color:purple}}@media screen (min-width: 100px) and screen (min-width: 300px){.c0 .c1 .c3{color:yellow}}'
    cssTest ojml, '.c0 {\n\tcolor:blue;\n}\n@media screen (min-width: 100px) {\n\t.c0 .c1 {\n\t\tcolor:red;\n\t}\n}\n@media screen (min-width: 100px) and screen (min-width: 200px) {\n\t.c0 .c1 {\n\t\tcolor:orange;\n\t}\n\t.c0 .c1.c2 {\n\t\tcolor:purple;\n\t}\n}\n@media screen (min-width: 100px) and screen (min-width: 300px) {\n\t.c0 .c1 .c3 {\n\t\tcolor:yellow;\n\t}\n}\n', minify:false

  it 'comma-seperated nested @media queries with complex selectors', ->
    ojml = oj.css

      '@media screen (min-width: 100px)':
        '.c1':
          color:'red'
          '@media handheld (max-width: 200px), print (max-width: 300px)':
            '&.c2':
              color:'orange'

    cssTest ojml, '@media screen (min-width: 100px){.c1{color:red}}@media screen (min-width: 100px) and handheld (max-width: 200px),screen (min-width: 100px) and print (max-width: 300px){.c1.c2{color:orange}}'
    cssTest ojml, '@media screen (min-width: 100px) {\n\t.c1 {\n\t\tcolor:red;\n\t}\n}\n@media screen (min-width: 100px) and handheld (max-width: 200px), screen (min-width: 100px) and print (max-width: 300px) {\n\t.c1.c2 {\n\t\tcolor:orange;\n\t}\n}\n', minify:false

  it 'comma-seperated nested @media queries with complex selectors', ->
    ojml = oj.css

      '@media screen (min-width: 100px)':
        '.c1':
          color:'red'
          '@media handheld (max-width: 200px), print (max-width: 300px)':
            '&.c2':
              color:'orange'

    cssTest ojml, '@media screen (min-width: 100px){.c1{color:red}}@media screen (min-width: 100px) and handheld (max-width: 200px),screen (min-width: 100px) and print (max-width: 300px){.c1.c2{color:orange}}'
    cssTest ojml, '@media screen (min-width: 100px) {\n\t.c1 {\n\t\tcolor:red;\n\t}\n}\n@media screen (min-width: 100px) and handheld (max-width: 200px), screen (min-width: 100px) and print (max-width: 300px) {\n\t.c1.c2 {\n\t\tcolor:orange;\n\t}\n}\n', minify:false

  it '@media monitor', ->
    ojml = oj.css
      '@media monitor':
        '.c1':
          color:'red'

    cssTest ojml, '.c1{color:red}'
    cssTest ojml, '.c1 {\n\tcolor:red;\n}\n', minify:false


  it '@media tablet', ->
    ojml = oj.css
      '@media tablet':
        '.c1':
          color:'red'

    cssTest ojml, '@media only screen and (min-width: 768px) and (max-width: 959px){.c1{color:red}}'
    cssTest ojml, '@media only screen and (min-width: 768px) and (max-width: 959px) {\n\t.c1 {\n\t\tcolor:red;\n\t}\n}\n', minify:false

  it '@media phone', ->
    ojml = oj.css
      '@media phone':
        '.c1':
          color:'red'

    cssTest ojml, '@media only screen and (max-width: 767px){.c1{color:red}}'
    cssTest ojml, '@media only screen and (max-width: 767px) {\n\t.c1 {\n\t\tcolor:red;\n\t}\n}\n', minify:false

  it '@media widescreen', ->
    ojml = oj.css
      '@media widescreen':
        '.c1':
          color:'red'

    cssTest ojml, '@media only screen and (min-width: 1200px){.c1{color:red}}'
    cssTest ojml, '@media only screen and (min-width: 1200px) {\n\t.c1 {\n\t\tcolor:red;\n\t}\n}\n', minify:false

  it '@media nested monitor phone tablet', ->
    ojml = oj.css
      '@media monitor':
        '.c1':
          color:'red'
          '@media phone':
            color:'blue'
          '@media tablet':
            color:'purple'

    cssTest ojml, '.c1{color:red}@media only screen and (max-width: 767px){.c1{color:blue}}@media only screen and (min-width: 768px) and (max-width: 959px){.c1{color:purple}}'
    cssTest ojml, '.c1 {\n\tcolor:red;\n}\n@media only screen and (max-width: 767px) {\n\t.c1 {\n\t\tcolor:blue;\n\t}\n}\n@media only screen and (min-width: 768px) and (max-width: 959px) {\n\t.c1 {\n\t\tcolor:purple;\n\t}\n}\n', minify:false

  it 'createType with css', ->
    FancyButton = oj.createType 'FancyButton',
      base:oj.Button
    FancyButton.css
      border:'1px solid purple'
      color:'orange'

    ojml = ->
      FancyButton 'My button'

    cssTest ojml, '.oj-FancyButton{border:1px solid purple;color:orange}'

    cssTest ojml, '.oj-FancyButton {\n\tborder:1px solid purple;\n\tcolor:orange;\n}\n', minify:false

  it 'createType with css and theme', ->
    FancyButton = oj.createType 'FancyButton',
      base:oj.Button
    FancyButton.css
      border:'1px solid purple'
      color:'orange'
    FancyButton.theme 'bluejay',
      color:'blue'

    ojml = ->
      FancyButton 'My button'

    cssTest ojml, '.oj-FancyButton{border:1px solid purple;color:orange}.oj-FancyButton.theme-bluejay{color:blue}'

    cssTest ojml, '.oj-FancyButton {\n\tborder:1px solid purple;\n\tcolor:orange;\n}\n.oj-FancyButton.theme-bluejay {\n\tcolor:blue;\n}\n', minify:false

  it 'output css to <style> tags', ->
    ojml = ->
      oj.css
        '.c1,.c2':
            color:'red'

    stylesTest ojml, '<style class="oj-style">.c1,.c2{color:red}</style>'
    stylesTest ojml, '<style class="oj-style">\n.c1,\n.c2 {\n\tcolor:red;\n}\n</style>', minify:false

  it 'output css to <style> tags with plugin', ->

    FancyButton = oj.createType 'FancyButton',
      base:oj.Button
    FancyButton.css
      border:'1px solid purple'
      color:'orange'
    FancyButton.theme 'bluejay',
      color:'blue'

    ojml = ->
      FancyButton 'My button'
      oj.css
        '.c1,.c2':
            color:'red'

    stylesTest ojml, '<style class="oj-FancyButton-style">.oj-FancyButton{border:1px solid purple;color:orange}.oj-FancyButton.theme-bluejay{color:blue}</style><style class="oj-style">.c1,.c2{color:red}</style>'

    stylesTest ojml, '<style class="oj-FancyButton-style">\n.oj-FancyButton {\n\tborder:1px solid purple;\n\tcolor:orange;\n}\n.oj-FancyButton.theme-bluejay {\n\tcolor:blue;\n}\n</style><style class="oj-style">\n.c1,\n.c2 {\n\tcolor:red;\n}\n</style>', minify:false
