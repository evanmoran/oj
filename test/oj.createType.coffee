# oj.tag.coffee
# Test oj.tag support including specific tags such as oj.div, oj.span, etc.

path = require 'path'
fs = require 'fs'

fileModifiedTime = (filepath, cb) ->
  fs.stat filepath, (err, data) ->
    return cb(err, data) if err
    cb(err, data.mtime)

oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.createType', ->

  _parentConstructor = null
  Parent = oj.createType 'Parent',
    constructor: (a1, a2, a3) ->
      console.log "Parent.constructor: #{__filename}: 20"
      _parentConstructor = a1

    methods:
      method: -> 'Parent.method'
      parentMethod: -> 'Parent.parentMethod'

    properties:
      value: 'Parent.value'
      readOnly: get: (-> 'Parent.readOnly')
      readWrite:
        get: -> if @_readWrite then ('Parent.readWrite' + @_readWrite) else 'Parent.readWriteDefault'
        set: (v) -> @_readWrite = v
      parentValue: 'Parent.parentValue'
      parentReadOnly: get: (-> 'Parent.parentReadOnly')
      parentReadWrite:
        get: (-> if @_parentReadWrite then 'Parent.parentReadWrite' + @_parentReadWrite else 'Parent.parentReadWriteDefault')
        set: ((v) -> @_parentReadWrite = v)

  Parent.method = (-> 'Parent.method')
  Parent.value = 'Parent.value'
  Parent.parentMethod = (-> 'Parent.parentMethod')
  Parent.parentValue = 'Parent.parentValue'

  oj.addProperties Parent,
    prop:
      get: -> if @_prop then ('Parent.prop' + @_prop) else 'Parent.prop'
      set: (v) -> @_prop = v

  oj.addProperties Parent,
    parentProp:
      get: -> if @_parentProp then ('Parent.parentProp' + @_parentProp) else 'Parent.parentProp'
      set: (v) -> @_parentProp = v

  _parentConstructor = null

  Child = oj.createType 'Child',
    extends: Parent

    constructor: (a1, a2, a3) ->
      super a2
      childConstructor = a1

    methods:
      method: -> 'Child.method'
      childMethod: -> 'Child.childMethod'

    properties:
      value: 'Child.value'
      readOnly: get: (-> 'Child.readOnly')
      readWrite:
        get: -> if @_readWrite then ('Child.readWrite' + @_readWrite) else 'Child.readWriteDefault'
        set: (v) -> @_readWrite = v
      childValue: 'Child.childValue'
      childReadOnly: get: (-> 'Child.childReadOnly')
      childReadWrite:
        get: (-> if @_childReadWrite then 'Child.childReadWrite' + @_childReadWrite else 'Child.childReadWriteDefault')
        set: ((v) -> @_childReadWrite = v)

  Child.method = (-> 'Child.method')
  Child.value = 'Child.value'
  Child.childMethod = (-> 'Child.childMethod')
  Child.childValue = 'Child.childValue'

  oj.addProperties Child,
    prop:
      get: -> if @_prop then ('Child.prop' + @_prop) else 'Child.prop'
      set: (v) -> @_prop = v

  oj.addProperties Child,
    childProp:
      get: -> if @_childProp then ('Child.childProp' + @_childProp) else 'Child.childProp'
      set: (v) -> @_childProp = v

  it 'exists', ->
    assert oj.createType != null, 'oj.createType is null'
    oj.tag.should.be.a 'function'

  it 'empty type', ->
    Empty = oj.createType 'Empty', {}
    empty = new Empty()
    expect(empty.properties).to.deep.equal []
    expect(empty.methods).to.deep.equal []

  it 'empty without new', ->
    parent = Parent()
    expect(parent.value).to.equal 'Parent.value'
    expect(parent.readOnly).to.equal 'Parent.readOnly'
    expect(parent.readWrite).to.equal 'Parent.readWriteDefault'

  it 'base type', ->
    parent = new Parent()
    expect(parent.properties).to.deep.equal ["parentReadOnly", "parentReadWrite", "parentValue", "readOnly", "readWrite", "value"]
    expect(parent.methods).to.deep.equal ['method', 'parentMethod']

  it 'base constructor', ->
    parent = new Parent('Parent.constructor')
    expect(_parentConstructor).to.equal 'Parent.constructor'

  it 'base type without new', ->
    Empty = oj.createType 'Empty', {}
    empty = Empty()
    expect(empty.properties).to.deep.equal []
    expect(empty.methods).to.deep.equal []

  it 'base type value property', ->
    parent = new Parent()
    expect(parent.value).to.equal 'Parent.value'

  it 'base type readonly property', ->
    parent = new Parent()
    expect(parent.readOnly).to.equal 'Parent.readOnly'
    parent.readOnly = 'DoesNotWork'
    expect(parent.readOnly).to.equal 'Parent.readOnly'

  it 'base type readwrite property', ->
    parent = new Parent()
    expect(parent.readWrite).to.equal 'Parent.readWriteDefault'
    parent.readWrite = 'Worked'
    expect(parent.readWrite).to.equal 'Parent.readWriteWorked'

  it 'base type method', ->
    parent = new Parent()
    expect(parent.method()).to.equal 'Parent.method'

  it 'base type class method', ->
    expect(Parent.method()).to.equal 'Parent.method'

  it 'base type class value', ->
    expect(Parent.value).to.equal 'Parent.value'

  it 'base type class property', ->
    expect(Parent.prop).to.equal 'Parent.prop'
    Parent.prop = 'Worked'
    expect(Parent.prop).to.equal 'Parent.propWorked'

  it 'base type value', ->
      parent = new Parent()
      expect(parent.method()).to.equal 'Parent.method'
  it 'inherited type', ->
    child = new Child()
    expect(child.properties).to.deep.equal ["childReadOnly", "childReadWrite", "childValue", "parentReadOnly", "parentReadWrite", "parentValue", "readOnly", "readWrite", "value"]
    expect(child.methods).to.deep.equal ['childMethod', 'method', 'parentMethod', ]

  it 'inherited type without new', ->
    child = Child()
    expect(child.method()).to.equal 'Child.method'

  it 'inherited type value property', ->
    child = new Child()
    expect(child.value).to.equal 'Child.value'
    expect(child.childValue).to.equal 'Child.childValue'
    expect(child.parentValue).to.equal 'Parent.parentValue'

  it 'inherited type readonly property', ->
    child = new Child()
    expect(child.readOnly).to.equal 'Child.readOnly'
    child.readOnly = 'DoesNotWork'
    expect(child.readOnly).to.equal 'Child.readOnly'

    expect(child.parentReadOnly).to.equal 'Parent.parentReadOnly'
    child.parentReadOnly = 'DoesNotWork'
    expect(child.parentReadOnly).to.equal 'Parent.parentReadOnly'

    expect(child.childReadOnly).to.equal 'Child.childReadOnly'
    child.childReadOnly = 'DoesNotWork'
    expect(child.childReadOnly).to.equal 'Child.childReadOnly'

  it 'inherited type readwrite property', ->
    child = new Child()
    expect(child.readWrite).to.equal 'Child.readWriteDefault'
    child.readWrite = 'Worked'
    expect(child.readWrite).to.equal 'Child.readWriteWorked'

  it 'inherited type method', ->
    child = new Child()
    expect(child.method()).to.equal 'Child.method'

  it 'inherited type class method', ->
    expect(Child.method()).to.equal 'Child.method'
    expect(Child.parentMethod()).to.equal 'Parent.parentMethod'
    expect(Child.childMethod()).to.equal 'Child.childMethod'

  it 'inherited type class value', ->
    expect(Child.value).to.equal 'Child.value'
    expect(Child.parentValue).to.equal 'Parent.parentValue'
    expect(Child.childValue).to.equal 'Child.childValue'

  it 'inherited type class property', ->
    expect(Child.prop).to.equal 'Child.prop'
    Child.prop = 'Worked'
    expect(Child.prop).to.equal 'Child.propWorked'

    expect(Child.parentProp).to.equal 'Parent.parentProp'
    Child.parentProp = 'Worked'
    expect(Child.parentProp).to.equal 'Parent.parentPropWorked'

    expect(Child.childProp).to.equal 'Child.childProp'
    Child.childProp = 'Worked'
    expect(Child.childProp).to.equal 'Child.childPropWorked'