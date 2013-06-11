# test/oj.compile.coffee
#
# Test oj.compile method for generating html, css, javascript

path = require 'path'
fs = require 'fs'
async = require 'async'

oj = require '../lib/oj.js'
oj.extend this

cssTest = (ojml, css, options) ->
  options = _.defaults {}, options,
    html:true
    css:true
    dom:false
    debug:false

  r = oj.compile options, ojml
  if not (options.css == false)
    expect(r.css).to.be.a 'string'
    expect(r.css).to.equal css
  else
    expect(r.css).to.not.exist

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

  it 'two rules', ->
    ojml = oj.css
      body:
        color: 'red'
      '.selector':
        border: '1px solid black'

    cssTest ojml, 'body{color:red}.selector{border:1px solid black}'

  it 'one rule debug', ->
    ojml = oj.css
      body:
        color: 'red'
    cssTest ojml, 'body {\n\tcolor:red;\n}\n', debug:true

  # TODO: This can only work if css minifier is really smart. Not sure if
  # there is a node minifier that supports this...
  it 'merged rules'
    # ojml = oj.css
    #   '.c1':
    #     color: 'red'
    #   '.c2':
    #     color: 'red'
    # cssTest ojml, '.c1,.c2{color:red}'

  it 'merged rules debug', ->
    ojml = oj.css
      '.c1':
        color: 'red'
      '.c2':
        color: 'red'
    cssTest ojml, '.c1 {\n\tcolor:red;\n}\n.c2 {\n\tcolor:red;\n}\n',debug:true

  it 'merged rules debug', ->
    ojml = oj.css
      '.c1':
        color: 'red'
      '.c2':
        color: 'red'
    cssTest ojml, '.c1 {\n\tcolor:red;\n}\n.c2 {\n\tcolor:red;\n}\n',debug:true

  it 'single comma seperated definition', ->
    ojml = oj.css
      '.c1,.c2':
          color:'red'

    cssTest ojml, '.c1,.c2{color:red}'

  it 'single nested definition', ->
    ojml = oj.css
      '.c1':
        '.c2':
          color:'red'

    cssTest ojml, '.c1 .c2{color:red}'

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

  it 'single nested definitions with &', ->
    ojml = oj.css
      '.c1':
        '&.red':
          color:'red'

    cssTest ojml, '.c1.red{color:red}'

  it 'single nested definitions with &:hover', ->
    ojml = oj.css
      '.c1':
        '.c2':
          '&:hover':
            color:'red'

    cssTest ojml, '.c1 .c2:hover{color:red}'

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

  ###


  OJ Example:
      css
        '.column-1-3':
          width:'33.3333%'
          '@media (max-width: 600px)':
            width:'100%'

  SASS Example:

      .column-1-3 {
        width: 33.3333%;
        @media (max-width: 600px) {
          width: 100%;
        }
      }

  RESULT:

      .column-1-3 {
        width: 33.3333%;
      }
      @media (max-width: 600px) {
        .column-1-3 {
          width: 100%;
        }
      }
  ###



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

  it 'nested @media query', ->

    ojml = oj.css
      '.c1':
        color:'blue'
        '@media print':
          color:'black'

    cssTest ojml, '.c1{color:blue}@media print{.c1{color:black}}'

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

  it 'comma-seperated nested @media queries with complex selectors', ->
    ojml = oj.css

      '@media screen (min-width: 100px)':
        '.c1':
          color:'red'
          '@media handheld (max-width: 200px), print (max-width: 300px)':
            '&.c2':
              color:'orange'

    cssTest ojml, '@media screen (min-width: 100px){.c1{color:red}}@media screen (min-width: 100px) and handheld (max-width: 200px),screen (min-width: 100px) and print (max-width: 300px){.c1.c2{color:orange}}'

  it 'comma-seperated nested @media queries with complex selectors', ->
    ojml = oj.css

      '@media screen (min-width: 100px)':
        '.c1':
          color:'red'
          '@media handheld (max-width: 200px), print (max-width: 300px)':
            '&.c2':
              color:'orange'

    cssTest ojml, '@media screen (min-width: 100px){.c1{color:red}}@media screen (min-width: 100px) and handheld (max-width: 200px),screen (min-width: 100px) and print (max-width: 300px){.c1.c2{color:orange}}'


  it '@media monitor', ->
    ojml = oj.css
      '@media monitor':
        '.c1':
          color:'red'

    cssTest ojml, '.c1{color:red}'

  it '@media tablet', ->
    ojml = oj.css
      '@media tablet':
        '.c1':
          color:'red'

    cssTest ojml, '@media only screen and (min-width: 768px) and (max-width: 959px){.c1{color:red}}'

  it '@media phone', ->
    ojml = oj.css
      '@media phone':
        '.c1':
          color:'red'

    cssTest ojml, '@media only screen and (max-width: 767px){.c1{color:red}}'

  it '@media widescreen', ->
    ojml = oj.css
      '@media widescreen':
        '.c1':
          color:'red'

    cssTest ojml, '@media only screen and (min-width: 1200px){.c1{color:red}}'

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
