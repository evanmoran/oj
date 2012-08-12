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

  div = 'div'
  span = 'span'
  str = 'str'
  str1 = 'one'
  str2 = 'two'
  str3 = 'three'

  it 'exists', ->
    assert oj.tag != null, 'oj.tag is null'
    oj.tag.should.be.a 'function'

  it 'name only', ->
    (oj.tag div).should.deep.equal oj: div

  it 'name, [String, ...]', ->
    (oj.tag div, str).should.deep.equal oj: div, _:str
    (oj.tag div, [str]).should.deep.equal oj: div, _:str
    (oj.tag div, [str1, str2]).should.deep.equal oj: div, _:[str1, str2]
    (oj.tag div, [str1, str2, str3]).should.deep.equal oj: div, _:[str1, str2, str3]

  it 'name, [Function, ...]', ->
    (oj.tag div, -> str).should.deep.equal oj: div, _:str
    (oj.tag div, [(-> str1), (-> str2), (->str3)]).should.deep.equal oj: div, _:[str1, str2, str3]
    (oj.tag div, (-> [str1, str2, str3])).should.deep.equal oj: div, _:[str1, str2, str3]
    (oj.tag div, (-> ( -> [str1, (->str2), str3]))).should.deep.equal oj: div, _:[str1, str2, str3]
    (oj.tag div, (-> [str1, (-> str2), str3])).should.deep.equal oj: div, _:[str1, str2, str3]

  it 'nested', ->
    (oj.tag div, (oj.tag div, str)).should.deep.equal oj: div, _:{oj: div, _:str}

  it 'nested list', ->
    (oj.tag div, [
      oj.tag div, str1
      oj.tag div, str2
    ]).should.deep.equal oj: div, _:[{oj: div, _:str1}, {oj: div, _:str2}]
