# oj.type.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../src/oj.coffee'
oj.extend this

describe 'oj.type', ->

  _parentConstructor = null
  Parent = oj.type 'Parent',
    constructor: ->

      expect(typeof @).to.equal 'object'
      expect(typeof @set).to.equal 'function'
      _parentConstructor = arguments[0]

    methods:
      method: -> 'Parent.method'
      superMethod: -> 'Parent.superMethod'
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

  _childConstructor = null
  Child = oj.type 'Child',
    base: Parent

    constructor: ->

      Child.base.constructor.apply @, arguments

      expect(typeof @).to.equal 'object'
      expect(typeof @set).to.equal 'function'
      _childConstructor = arguments[0]

    methods:
      method: -> 'Child.method'
      superMethod: -> Child.base.superMethod() + '.Child.superMethod'
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

  _grandChildConstructor = null
  GrandChild = oj.type 'GrandChild',
    base: Child

    constructor: ->
      GrandChild.base.constructor.apply @, arguments
      _grandChildConstructor = arguments[0]

    methods:
      method: -> 'GrandChild.method'
      superMethod: -> GrandChild.base.superMethod() + '.GrandChild.superMethod'
      grandChildMethod: -> 'GrandChild.grandChildMethod'

    properties:
      value: 'GrandChild.value'
      readOnly: get: (-> 'GrandChild.readOnly')
      readWrite:
        get: -> if @_readWrite then ('GrandChild.readWrite' + @_readWrite) else 'GrandChild.readWriteDefault'
        set: (v) -> @_readWrite = v
      grandChildValue: 'GrandChild.grandChildValue'
      grandChildReadOnly: get: (-> 'GrandChild.grandChildReadOnly')
      grandChildReadWrite:
        get: (-> if @_grandChildReadWrite then 'GrandChild.grandChildReadWrite' + @_grandChildReadWrite else 'GrandChild.grandChildReadWriteDefault')
        set: ((v) -> @_grandChildReadWrite = v)

  GrandChild.method = (-> 'GrandChild.method')
  GrandChild.value = 'GrandChild.value'
  GrandChild.grandChildMethod = (-> 'GrandChild.grandChildMethod')
  GrandChild.grandChildValue = 'GrandChild.grandChildValue'

  oj.addProperties GrandChild,
    prop:
      get: -> if @_prop then ('GrandChild.prop' + @_prop) else 'GrandChild.prop'
      set: (v) -> @_prop = v

  oj.addProperties GrandChild,
    grandChildProp:
      get: -> if @_grandChildProp then ('GrandChild.grandChildProp' + @_grandChildProp) else 'GrandChild.grandChildProp'
      set: (v) -> @_grandChildProp = v

  it 'exists', ->
    assert oj.type != null, 'oj.type is null'
    oj.type.should.be.a 'function'


  it 'empty type', ->
    Empty = oj.type 'Empty', {}
    empty = new Empty()
    expect(empty.type).to.equal Empty
    expect(empty.typeName).to.equal 'Empty'
    expect(empty.properties).to.deep.equal []
    expect(empty.methods).to.deep.equal []

  it 'empty type without new', ->
    Empty = oj.type 'Empty', {}
    empty = Empty()
    expect(empty.type).to.equal Empty
    expect(empty.typeName).to.equal 'Empty'
    expect(empty.properties).to.deep.equal []
    expect(empty.methods).to.deep.equal []

  it 'simple type', ->

    # Fixing current date for unit test consistency
    currentDate = new Date(2013, 1,1)
    User = oj.type 'User',
      constructor: (args) ->
        @set args

      # Types can define properties
      properties:
        name: 'default name'
        birthDate: null

      # Types can define methods
      methods:
        age: ->
          # Calculate age from @birthDate
          today = currentDate
          age = today.getFullYear() - @birthDate.getFullYear()
          m = today.getMonth() - @birthDate.getMonth()
          if m < 0 or (m == 0 and today.getDate() < @birthDate.getDate())
            age--
          age

    birthDate = new Date 1945, 6, 23

    user = User name: 'Joseph', birthDate: birthDate

    expect(user.name).to.equal 'Joseph'
    expect(user.birthDate).to.equal birthDate
    expect(user.age()).to.equal 67

  it 'simple type with default', ->

    User = oj.type 'User',
      constructor: (args) ->
        @set args

      # Types can define properties
      properties:
        nameWithDefault: 'Default'

    user = User nameWithDefault: 'Joseph'
    expect(user.nameWithDefault).to.equal 'Joseph'

  it 'simple types have get and set', ->
    T = oj.type 'T',
      constructor: (args) ->
        @set args
      properties:
        prop1: 42
        prop2:
          get: (v) -> @_prop2
          set: (v) -> @_prop2 = v; return

    t = new T(prop1: 1, prop2: 2)

    # Get one at a time
    expect(t.get('prop0')).to.not.exist
    expect(t.get('prop1')).to.equal 1
    expect(t.get('prop2')).to.equal 2

    # Get all
    getAll = t.get()
    expect(getAll.prop1).to.equal 1
    expect(getAll.prop2).to.equal 2

    # Set one
    t.set 'prop1', 11
    expect(t.get 'prop1').to.equal 11
    expect(t.get 'prop2').to.equal 2
    expect(t.get().prop1).to.equal 11

    # Set one that isn't a property
    t.set 'prop0', 0
    expect(t.get 'prop0').to.not.exist
    expect(t.get().prop0).to.not.exist

    # Set all
    t.set prop0:'zero', prop1: 111, prop2: 222
    expect(t.get('prop0')).to.not.exist
    expect(t.get('prop1')).to.equal 111
    expect(t.get('prop2')).to.equal 222
    getAll = t.get()
    expect(getAll.prop0).to.not.exist
    expect(getAll.prop1).to.equal 111
    expect(getAll.prop2).to.equal 222

  it 'base type', ->
    parent = new Parent()
    expect(parent.properties).to.deep.equal ["parentReadOnly", "parentReadWrite", "parentValue", "readOnly", "readWrite", "value"]
    expect(parent.methods).to.deep.equal ['method', 'parentMethod', 'superMethod']

  it 'base type without new', ->
    parent = Parent()
    expect(parent.typeName).to.equal 'Parent'
    expect(parent.value).to.equal 'Parent.value'
    expect(parent.method()).to.equal 'Parent.method'

  it 'base type constructor', ->
    parent = new Parent('Parent.constructor')
    expect(_parentConstructor).to.equal 'Parent.constructor'

  it 'base type constructor without new', ->
    parent = Parent('Parent.constructor')
    expect(_parentConstructor).to.equal 'Parent.constructor'

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

  it 'base type methods', ->
    parent = new Parent()
    expect(parent.method()).to.equal 'Parent.method'
    expect(parent.parentMethod()).to.equal 'Parent.parentMethod'

  it 'base type class methods', ->
    expect(Parent.method()).to.equal 'Parent.method'
    expect(Parent.parentMethod()).to.equal 'Parent.parentMethod'

  it 'base type class value', ->
    expect(Parent.value).to.equal 'Parent.value'
    expect(Parent.parentValue).to.equal 'Parent.parentValue'

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
    expect(child.methods).to.deep.equal ['childMethod', 'method', 'parentMethod', 'superMethod']

  it 'inherited type with constructor', ->
    child = new Child('Child.constructor', 'Child.constructor')
    expect(_childConstructor).to.equal 'Child.constructor'
    expect(_parentConstructor).to.equal 'Child.constructor'

  it 'inherited type without new', ->
    child = Child()
    expect(child.type).to.equal Child
    expect(child.typeName).to.equal 'Child'
    expect(child.childValue).to.equal 'Child.childValue'
    expect(child.value).to.equal 'Child.value'
    expect(child.method()).to.equal 'Child.method'

  it 'inherited type without new, with constructor', ->
    child = Child('Child.constructor', 'Child.constructor')
    expect(_childConstructor).to.equal 'Child.constructor'
    expect(_parentConstructor).to.equal 'Child.constructor'

  it 'inherited type value property', ->
    child = new Child()
    expect(child.type).to.equal Child
    expect(child.typeName).to.equal 'Child'
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

  it 'inherited type class methods inherit', ->
    expect(Child.method()).to.equal 'Child.method'
    expect(Child.parentMethod()).to.equal 'Parent.parentMethod'
    expect(Child.childMethod()).to.equal 'Child.childMethod'

  it 'inherited type methods inherit', ->
    child = new Child()
    expect(child.method()).to.equal 'Child.method'
    expect(child.childMethod()).to.equal 'Child.childMethod'
    expect(child.parentMethod()).to.equal 'Parent.parentMethod'

  it 'inherited type methods call super', ->
    child = new Child()
    expect(child.superMethod()).to.equal 'Parent.superMethod.Child.superMethod'

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

  it 'deeply inherited type', ->
    grandChild = new GrandChild()
    expect(grandChild.properties).to.deep.equal ["childReadOnly", "childReadWrite", "childValue", "grandChildReadOnly", "grandChildReadWrite", "grandChildValue", "parentReadOnly", "parentReadWrite", "parentValue", "readOnly", "readWrite", "value"]
    expect(grandChild.methods).to.deep.equal ['childMethod', 'grandChildMethod', 'method', 'parentMethod', 'superMethod']

  it 'deeply inherited type with constructor', ->
    grandChild = new GrandChild('GrandChild.constructor', 'GrandChild.constructor')
    expect(_grandChildConstructor).to.equal 'GrandChild.constructor'
    expect(_parentConstructor).to.equal 'GrandChild.constructor'
    expect(_childConstructor).to.equal 'GrandChild.constructor'

  it 'deeply inherited type without new', ->
    grandChild = GrandChild()
    expect(grandChild.type).to.equal GrandChild
    expect(grandChild.typeName).to.equal 'GrandChild'
    expect(grandChild.value).to.equal 'GrandChild.value'
    expect(grandChild.grandChildValue).to.equal 'GrandChild.grandChildValue'
    expect(grandChild.childValue).to.equal 'Child.childValue'
    expect(grandChild.parentValue).to.equal 'Parent.parentValue'

  it 'deeply inherited type without new, with constructor', ->
    grandChild = GrandChild('GrandChild.constructor', 'GrandChild.constructor')
    expect(_grandChildConstructor).to.equal 'GrandChild.constructor'
    expect(_childConstructor).to.equal 'GrandChild.constructor'
    expect(_parentConstructor).to.equal 'GrandChild.constructor'

  it 'deeply inherited type value property', ->
    grandChild = new GrandChild()
    expect(grandChild.type).to.equal GrandChild
    expect(grandChild.typeName).to.equal 'GrandChild'
    expect(grandChild.value).to.equal 'GrandChild.value'
    expect(grandChild.grandChildValue).to.equal 'GrandChild.grandChildValue'
    expect(grandChild.parentValue).to.equal 'Parent.parentValue'

  it 'deeply inherited type readonly property', ->
    grandChild = new GrandChild()
    expect(grandChild.readOnly).to.equal 'GrandChild.readOnly'
    grandChild.readOnly = 'DoesNotWork'
    expect(grandChild.readOnly).to.equal 'GrandChild.readOnly'

    expect(grandChild.grandChildReadOnly).to.equal 'GrandChild.grandChildReadOnly'
    grandChild.grandChildReadOnly = 'DoesNotWork'
    expect(grandChild.grandChildReadOnly).to.equal 'GrandChild.grandChildReadOnly'

  it 'deeply inherited type readwrite property', ->
    grandChild = new GrandChild()
    expect(grandChild.readWrite).to.equal 'GrandChild.readWriteDefault'
    grandChild.readWrite = 'Worked'
    expect(grandChild.readWrite).to.equal 'GrandChild.readWriteWorked'

  it 'deeply inherited type methods correctly inherit', ->
    grandChild = new GrandChild()
    expect(grandChild.method()).to.equal 'GrandChild.method'
    expect(grandChild.childMethod()).to.equal 'Child.childMethod'
    expect(grandChild.parentMethod()).to.equal 'Parent.parentMethod'

  it 'deeply inherited type methods call super', ->
    grandChild = new GrandChild()
    expect(grandChild.superMethod()).to.equal 'Parent.superMethod.Child.superMethod.GrandChild.superMethod'

  it 'deeply inherited type class method', ->
    expect(GrandChild.method()).to.equal 'GrandChild.method'
    expect(GrandChild.parentMethod()).to.equal 'Parent.parentMethod'
    expect(GrandChild.grandChildMethod()).to.equal 'GrandChild.grandChildMethod'

  it 'deeply inherited type class value', ->
    expect(GrandChild.value).to.equal 'GrandChild.value'
    expect(GrandChild.parentValue).to.equal 'Parent.parentValue'
    expect(GrandChild.grandChildValue).to.equal 'GrandChild.grandChildValue'

  it 'deeply inherited type class property', ->
    expect(GrandChild.prop).to.equal 'GrandChild.prop'
    GrandChild.prop = 'Worked'
    expect(GrandChild.prop).to.equal 'GrandChild.propWorked'

    expect(GrandChild.parentProp).to.equal 'Parent.parentProp'
    GrandChild.parentProp = 'Worked'
    expect(GrandChild.parentProp).to.equal 'Parent.parentPropWorked'

    expect(GrandChild.grandChildProp).to.equal 'GrandChild.grandChildProp'
    GrandChild.grandChildProp = 'Worked'
    expect(GrandChild.grandChildProp).to.equal 'GrandChild.grandChildPropWorked'

  it 'deeply inherited type calls constructor minimally', ->
    _increment = 0
    P = oj.type 'P',
      constructor: ->
        _increment++

    C = oj.type 'C',
      base: P
      constructor: ->
        C.base.constructor.apply @, arguments
        _increment++

    GC = oj.type 'GC',
      base: C
      constructor: ->
        GC.base.constructor.apply @, arguments
        _increment++

    p = new P()
    expect(_increment).to.equal 1

    _increment = 0
    c = new C()
    expect(_increment).to.equal 2

    _increment = 0
    gc = new GC()
    expect(_increment).to.equal 3

  it 'deeply inherited type calls constructor minimally without new', ->
    _increment = 0
    P = oj.type 'P',
      constructor: ->
        _increment++

    C = oj.type 'C',
      base: P
      constructor: ->
        C.base.constructor.apply @, arguments
        _increment++

    GC = oj.type 'GC',
      base: C
      constructor: ->
        GC.base.constructor.apply @, arguments
        _increment++

    p = P()
    expect(_increment).to.equal 1

    _increment = 0
    c = C()
    expect(_increment).to.equal 2

    _increment = 0
    gc = GC()
    expect(_increment).to.equal 3


  it 'inherited type automatically creates constructor calling base', ->
    # P constructor
    _increment = 0
    P = oj.type 'P',
      constructor: (v) ->
        if v?
          @prop = v
        _increment += @prop
      properties:
        prop: 24

    C = oj.type 'C',
      base: P
      # Purposely don't create a constructor because the default constructor
      # should be automatically implemented to call base.constructor
      properties:
        prop: 42

    _increment = 0
    p = new P()
    expect(p.prop).to.equal 24
    expect(_increment).to.equal 24

    _increment = 0
    c = new C()
    expect(c.prop).to.equal 42
    expect(_increment).to.equal 42

    _increment = 0
    p = P(84)
    expect(p.prop).to.equal 84
    expect(_increment).to.equal 84

    _increment = 0
    c = C(84)
    expect(c.prop).to.equal 84
    expect(_increment).to.equal 84
