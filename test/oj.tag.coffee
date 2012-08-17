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

  # it 'exists', ->
  #   assert oj.tag != null, 'oj.tag is null'
  #   oj.tag.should.be.a 'function'

  # it 'name only', ->
  #   (oj.tag 'div').should.deep.equal oj: 'div'
  #   (div()).should.deep.equal oj: 'div'
  #   (span()).should.deep.equal oj: 'span'

  # it 'fancy pants style', ->
  #   (div ->
  #     span str1
  #     div str2
  #   ).should.deep.equal oj: 'div', _:[{oj: 'span', _:str1}, {oj: 'div', _:str2}]


  # it 'name, [String, ...]', ->
  #   (div str).should.deep.equal oj: 'div', _:str
  #   (div [str]).should.deep.equal oj: 'div', _:str
  #   (div [str1, str2]).should.deep.equal oj: 'div', _:[str1, str2]
  #   (div [str1, str2, str3]).should.deep.equal oj: 'div', _:[str1, str2, str3]

  it 'name, [Function, ...]', ->
    (div -> str).should.deep.equal oj: 'div', _:str
    (div div str).should.deep.equal oj: 'div', _:{oj: 'div', _:str}

    # (div div str).should.deep.equal ['div', ['div', 'str']]

    (div (-> [str1, str2, str3])).should.deep.equal oj: 'div', _:[str1, str2, str3]
    (div [(-> str1), (-> str2), (->str3)]).should.deep.equal oj: 'div', _:[str1, str2, str3]

  it 'nested', ->
    (div (div str)).should.deep.equal oj: 'div', _:{oj: 'div', _:str}
    (div div str).should.deep.equal oj: 'div', _:{oj: 'div', _:str}

  it 'nested list', ->
    (div [
      div str1
      div str2
    ]).should.deep.equal oj: 'div', _:[{oj: 'div', _:str1}, {oj: 'div', _:str2}]

    (div ->
      div str1
      span ->
        div str2
        div str3
      div str4
    ).should.deep.equal oj: 'div', _:[
        {oj: 'div', _:str1}
        {oj: 'span', _:[
          {oj: 'div', _:str2}
          {oj: 'div', _:str3}
        ]}
        {oj: 'div', _:str4}
      ]


  it 'multiple tag types (div, span)', ->
    (div [
      span str1
      div str2
    ]).should.deep.equal oj: 'div', _:[{oj: 'span', _:str1}, {oj: 'div', _:str2}]
