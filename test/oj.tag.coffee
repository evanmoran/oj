# oj.tag.coffee
# Test oj.tag support including specific tags such as oj.div, oj.span, etc.

path = require 'path'
fs = require 'fs'
async = require 'async'

fileModifiedTime = (filepath, cb) ->
  fs.stat filepath, (err, data) ->
    return cb(err, data) if err
    cb(err, data.mtime)

oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.tag', ->

  div = oj.div
  span = oj.span
  str = 'str'
  str1 = 'one'
  str2 = 'two'
  str3 = 'three'
  str4 = 'four'

  it 'exists', ->
    assert oj.tag != null, 'oj.tag is null'
    oj.tag.should.be.a 'function'

  it 'name only', ->
    (oj.tag 'div').should.deep.equal ['div']
    (div()).should.deep.equal ['div']
    (span()).should.deep.equal ['span']
    (oj()).should.deep.equal ['oj']

  it 'name, [String, ...]', ->
    (div str).should.deep.equal ['div', str]
    (div str1, str2).should.deep.equal ['div', str1, str2]
    (div str1, str2, str3).should.deep.equal ['div', str1, str2, str3]

  it 'name, [Function, ...]', ->
    (div -> str).should.deep.equal ['div', str]
    (div (-> str1), (->str2), str3).should.deep.equal ['div', str1, str2, str3]

  it 'name, attributes', ->
    (div (span str)).should.deep.equal ['div', ['span', 'str']]

    (div class:'cls', id:1, ->
      span ->
        div 1
        div 2
    ).should.deep.equal ['div', class:'cls', id:1, ['span', ['div', 1], ['div', 2]]]

  it 'name empty attributes', ->
    (div {}).should.deep.equal ['div']
    (div {}, (->)).should.deep.equal ['div']

  it 'string attributes', ->
    (div foo:'bar').should.deep.equal ['div', {'foo':'bar'}]
    (div foo:'').should.deep.equal ['div', {'foo':''}]

  it 'boolean attributes', ->
    (div foo:true).should.deep.equal ['div', {'foo':true}]

  it 'null attributes', ->
    (div foo:null).should.deep.equal ['div', {'foo':null}]

  it 'name with object', ->
    user = name:'Sam'
    expect(div c:'cls', user.name).to.deep.equal ['div', c:'cls', 'Sam']
    expect(div user.name, c:'cls').to.deep.equal ['div', c:'cls', 'Sam']

  it 'nested functions', ->
    (div (span str)).should.deep.equal ['div', ['span', 'str']]

    (div ->
      span ->
        div 1
        div 2
    ).should.deep.equal ['div', ['span', ['div', 1], ['div', 2]]]

  it 'mixed OJML and calls', ->
    (div ['div', str1]).should.deep.equal ['div',['div', str1]]
    (div ['div', str1], (div ['div', str2])).should.deep.equal ['div',['div', str1], ['div',['div', str2]]]

  it 'nested arguments', ->
    (div (div str1), (div str2)).should.deep.equal ['div', ['div', str1], ['div', str2]]

    (div ->
      div str1
      span ->
        div str2
        div str3
      div str4
    ).should.deep.equal ['div',
        ['div', str1]
        ['span',
          ['div', str2]
          ['div', str3]
        ]
        ['div', str4]
      ]

  it 'multiple tag types (div, span)', ->
    (div ->
      span str1
      div str2
    ).should.deep.equal ['div', ['span', str1], ['div', str2]]

  it 'empty function', ->
    (div ->).should.deep.equal ['div']

  it 'oj empty function', ->
    (oj ->).should.deep.equal ['oj']

  it 'oj function', ->
    (oj ->
      div 1
      div 2
    ).should.deep.equal ['oj', ['div',1],['div',2]]


  it 'oj function stops global propagation', ->
    ojml2 = null
    ojml = div ->
      div 1
      ojml2 = oj ->
        div 2
        div 3

    # oj stops propagation
    ojml.should.deep.equal ['div', ['div', 1]]

    # but correctly returns its children
    ojml2.should.deep.equal ['oj', ['div', 2], ['div', 3] ]
