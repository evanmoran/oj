
oj
==============================================================================
A unified templating framework for the people. Thirsty people.

oj function
-------------------------------------------------------------------------------

Convert ojml to dom

    oj = ->

  oj function acts like a tag method that doesn't emit

      oj._argsPush()
      ojml = oj.emit.apply @, arguments
      oj._argsPop()
      ojml

Export Model to NodeJS or globally
-------------------------------------------------------------------------------
  Remember root context

    root = @

  Define oj version

    oj.version = '0.1.4'

  Detect if this is client or server-side

    oj.isClient = not process?.versions?.node

  Store jQuery reference as either the global reference or as required through `jquery2`.
  This allows this reference to be included as a script tag, included through npm, or overriden.

    if typeof $ != 'undefined'
      oj.$ = $
    else if typeof require != 'undefined'
      try
        oj.$ = require 'jquery'

  Export as a module in node

    if typeof module != 'undefined'
      exports = module.exports = oj

  Export globally if not in node

    else
      root['oj'] = oj

  Reference ourselves for template files to see

    oj.oj = oj

oj.load
-------------------------------------------------------------------------------
Load the page specified generating necessary html, css, and client side events.

    oj.load = (page) ->

  Defer dom manipulation until the page is ready

      oj.$ ->

        oj.$.ojBody (require page)

  Trigger events bound through onload

        oj.onload()

oj.onload
-------------------------------------------------------------------------------
Enlist in onload action.

    _onLoadQueue = queue:[], loaded:false
    oj.onload = (f) ->

  Call everything if no arguments

      if oj.isUndefined f
        _onLoadQueue.loaded = true
        while (f = _onLoadQueue.queue.shift())
          f()

  Call load if already loaded

      else if _onLoadQueue.loaded
        f()

  Queue function for later

      else
        _onLoadQueue.queue.push f
      return

oj.emit
-------------------------------------------------------------------------------
Emit arguments as a tag would.
Used by plugins to group multiple elements as if it is a single tag.

    oj.emit = ->
      ojml = oj.tag 'oj', arguments...

oj.id
-----------------------------------------------------------------------------
Generate a unique oj id

    oj.id = (len, chars) ->
      'oj' + oj.guid len, chars

oj.guid
-----------------------------------------------------------------------------
Generate a unique guid

    _randomInteger = (min, max) ->
      return null if min == null or max == null or min > max
      diff = max - min;
      # random int from zero to number minus one
      rnd = Math.floor Math.random() * (diff + 1)
      rnd + min

    _chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".split ''
    oj.guid = (len = 8, chars = _chars) ->
      # Default arguments
      base = chars.length

      # Calculate how many chars can be determined by each random call
      charsPerRand = Math.floor Math.log(Math.pow(2,31)-1) / Math.log(base)
      randMin = 0
      randMax = Math.pow(base, charsPerRand)-1

      # Calculate random chars by calling random the minimum number of times
      output = ""
      for i in [0...len]
        # Generate random number
        if i % charsPerRand == 0
          rand = _randomInteger randMin, randMax
        charNext = chars[rand % base]
        output += charNext
        rand = Math.floor(rand / base)

      output

Type Helpers
------------------------------------------------------------------------------

Short names for common prototype and method names

    ArrayP = Array.prototype
    FuncP = Function.prototype
    ObjP = Object.prototype

    slice = ArrayP.slice
    unshift = ArrayP.unshift
    concat = ArrayP.concat

Type helper for oj types

    oj.isOJ = (obj) -> !!(obj?.isOJ)

Type helper for event enabled objects such as Backbone models

    oj.isEvent = (obj) -> !!(obj and obj.on and obj.off and obj.trigger)

Type helper for DOM element types

    oj.isDOM = (obj) -> !!(obj and obj.nodeType?)
    oj.isDOMElement = (obj) -> !!(obj and obj.nodeType == 1)
    oj.isDOMAttribute = (obj) -> !!(obj and obj.nodeType == 2)
    oj.isDOMText = (obj) -> !!(obj and obj.nodeType == 3)

Type helper for jQuery

    oj.isjQuery = (obj) -> !!(obj and obj.jquery)

Type helpers for basic types. Based on [underscore.js](http://underscorejs.org/)

    oj.isUndefined = (obj) -> obj == undefined
    oj.isBoolean = (obj) -> obj == true or obj == false or ObjP.toString.call(obj) == '[object Boolean]'
    oj.isNumber = (obj) -> !!(obj == 0 or (obj and obj.toExponential and obj.toFixed))
    oj.isString = (obj) -> !!(obj == '' or (obj and obj.charCodeAt and obj.substr))
    oj.isDate = (obj) -> !!(obj and obj.getTimezoneOffset and obj.setUTCFullYear)
    oj.isFunction = (obj) -> typeof obj == 'function'
    oj.isArray = Array.isArray or (obj) -> ObjP.toString.call(obj) == '[object Array]'
    oj.isRegEx = (obj) -> ObjP.toString.call(obj) == '[object RegExp]'
    oj.isArguments = (obj) -> ObjP.toString.call(obj) == '[object Arguments]'

Type helper for is defined

    oj.isDefined = (obj) -> not (typeof obj == 'undefined')

oj.typeOf
-------------------------------------------------------------------------------
Mimic behavior of built-in typeof operator and integrate jQuery, Backbone, and OJ types

    oj.typeOf = (any) ->

      return 'null' if any == null
      t = typeof any
      if t == 'object'
        if oj.isArray any                     then t = 'array'
        else if oj.isOJ any                   then t = any.typeName
        else if oj.isRegEx any                then t = 'regexp'
        else if oj.isDate any                 then t = 'date'
        else if oj.isDOMElement any           then t = 'dom-element'
        else if oj.isDOMText any              then t = 'dom-text'
        else if oj.isDOMAttribute any         then t = 'dom-attribute'
        else if oj.isjQuery any               then t = 'jquery'
        else                                  t = 'object'
      t

oj.parse: Convert string to basic type, number, boolean, null, or undefined

    oj.parse = (str) ->
      if str == 'undefined'
        undefined
      else if str == 'null'
        null
      else if str == 'true'
        true
      else if str == 'false'
        false
      else if !(isNaN(number = parseFloat str))
        number
      else
        str

oj.isObject: Determine if object is a vanilla object type

    oj.isObject = (obj) -> (oj.typeOf obj) == 'object'

Utility Helpers
------------------------------------------------------------------------------

    _isCapitalLetter = (c) -> !!(c.match /[A-Z]/)
    _identity = (v) -> v
    _has = (obj, key) -> ObjP.hasOwnProperty.call(obj, key)
    _keys = Object.keys || (obj) ->
      throw 'Invalid object' if obj != Object(obj)
      keys = [];
      for key of obj
        if _has obj, key
          keys[keys.length] = key;
      keys
    _values = (obj) ->
      throw 'Invalid object' if obj != Object(obj)
      out = []
      _each obj, (v) -> out.push v
      out

    _flatten = (array, shallow) ->
      _reduce array, ((memo, value) ->
        if oj.isArray value
          return memo.concat(if shallow then value else _flatten(value))
        memo[memo.length] = value
        memo
      ), []

    _reduce = (obj = [], iterator, memo, context) ->
      initial = arguments.length > 2
      if ArrayP.reduce and obj.reduce == ArrayP.reduce
        if context
          iterator = _bind iterator, context
        return if initial then obj.reduce iterator, memo else obj.reduce iterator

      _each obj, (value, index, list) ->
        if (!initial)
          memo = value
          initial = true
        else
          memo = iterator.call context, memo, value, index, list

      if !initial
        throw new TypeError 'Reduce of empty array with no initial value'
      memo

      ctor = ->

_bind: Helper to bind context to function

      _bind = (func, context) ->
        if func.bind == FuncP.bind and FuncP.bind
          return FuncP.bind.apply func, slice.call(arguments, 1)

  Safari 5.1 doesn't implement bind in some iOS versions
  TODO: Remove when iOS 6 reaches 95% adoption

        args = slice.call arguments, 2
        return bound = ->
          unless this instanceof bound
            return func.apply context, args.concat(slice.call arguments)
          ctor.prototype = func.prototype
          self = new ctor
          result = func.apply self, args.concat(slice.call(arguments))
          if Object(result) == result
            return result
          self

    _sortedIndex = (array, obj, iterator = _identity) ->
      low = 0
      high = array.length;
      while low < high
        mid = (low + high) >> 1;
        if iterator(array[mid]) < iterator(obj) then low = mid + 1 else high = mid;
      low


  _indexOf

    _indexOf = (array, item, isSorted) ->
      return -1 unless array?
      if isSorted
        i = _sortedIndex array, item
        return if array[i] == item then i else -1
      if ArrayP.indexOf and array.indexOf == ArrayP.indexOf
        return array.indexOf item
      -1

  _toArray

    _toArray = (obj) ->
      return [] if !obj
      return slice.call obj if oj.isArray obj
      return slice.call obj if oj.isArguments obj
      return obj.toArray() if obj.toArray and oj.isFunction(obj.toArray)
      _values obj

  _isEmpty

    # Determine if object or array is empty
    _isEmpty = (obj) ->
      return obj.length == 0 if oj.isArray obj
      for k of obj
        if _has obj, k
          return false
      true

  _clone

    _clone = (obj) ->
      return obj unless (oj.isArray obj) or (oj.isObject obj)
      if oj.isArray obj then obj.slice() else _extend {}, obj

  _contains

    _contains = (obj, target) ->
      if not obj?
        return false
      if ArrayP.indexOf and obj.indexOf == ArrayP.indexOf
        return obj.indexOf(target) != -1
      _some obj, (value) -> value == target

  _some

    _some = (obj, iterator, context) ->
        iterator ?= _identity
        result = false
        if not obj?
          return result
        if ArrayP.some and obj.some == ArrayP.some
          return obj.some iterator, context
        _each obj, (value, index, list) ->
          if result or (result = iterator.call(context, value, index, list))
            return breaker
        return !!result

_setObject: Set object deeply and ensure each part is an object

    _setObject = (obj, keys..., value) ->

      o = obj
      for k,ix in keys

  Initialize key to empty object if necessary

        if typeof o[k] != 'object'

          o[k] = {} unless (typeof o[k] == 'object')

  Set final value if this is the last key

        if ix == keys.length - 1
          o[k] = value
          break

  Continue deeper

        o = o[k]

      obj

Functional Helpers
------------------------------------------------------------------------
  _each

    _breaker = {}

    _each = (col, iterator, context) ->

      return if col == null
      if ArrayP.forEach and col.forEach == ArrayP.forEach
        col.forEach iterator, context
      else if oj.isArray col
        for v, i in col
          if iterator.call(context, v, i, col) == _breaker
            return _breaker
      else
        for k, v of col
          if _has col, k
            if iterator.call(context, v, k, col) == _breaker
              return _breaker

  _map

    oj._map = (obj, iterator, options = {}) ->

      context = options.context
      recurse = options.recurse
      evaluate = options.evaluate

      # Recurse if necessary
      iterator_ = iterator
      if recurse
        do (options) ->
          iterator_ = (v,k,o) ->
            options_ = _extend (_clone options), (key: k, object: v)
            oj._map v, iterator, options_

      # Evaluate functions if necessary
      if oj.isFunction obj

        # Functions pass through if evaluate isn't set
        return obj unless evaluate

        while evaluate and oj.isFunction obj
          obj = obj()

      out = obj

      # Array case
      if oj.isArray obj
        out = []
        return out unless obj
        return (obj.map iterator_, context) if ArrayP.map and obj.map == ArrayP.map
        _each(obj, ((v, ix, list) ->
          out[out.length] = iterator_.call context, v, ix, list
        ))

        if obj.length == +obj.length
          out.length = obj.length

      # Object case
      else if oj.isObject obj
        out = {}
        return out unless obj
        for k,v of obj
          # Returning undefined will omit the thing
          if (r = iterator_.call(context, v, k, obj)) != undefined
            out[k] = r
      # Basis of recursive case
      else
        return iterator.call context, obj, options.key, options.object,
      out

  _extend

    _extend = (obj) ->
      _each(slice.call(arguments, 1), ((source) ->
        for key, value of source
          obj[key] = value
      ))
      obj

  _defaults

    _defaults = (obj) ->
      _each(slice.call(arguments, 1), ((source) ->
        for prop of source
          if not obj[prop]?
            obj[prop] = source[prop]
      ))
      obj

  _omit

    _omit = (obj) ->
      copy = {}
      keys = concat.apply ArrayP, slice.call(arguments, 1)
      for key of obj
        if not _contains keys, key
          copy[key] = obj[key]
      copy

  _uniqueSort

    _uniqueSort = (array, isSorted = false) ->
      if not isSorted
        array.sort()
      out = []
      for item,ix in array
        if ix > 0 and array[ix-1] == array[ix]
          continue
        out.push item
      out

  _uniqueSortedUnion

    _uniqueSortedUnion = (arr, arr2) ->
      _uniqueSort (arr.concat arr2)


Indexing Helpers
-----------------------------------------------------------------------------

  _boundOrThrow: Bound index to allow negatives, throw when out of range

    _boundOrThrow = (ix, count, message, method) ->
      ixNew = if ix < 0 then ix + count else ix
      unless 0 <= ixNew and ixNew < count
        throw new Error("oj.#{method}#{message} is out of bounds (#{ix} in [0,#{count-1}])")
      ixNew

String Helpers
-----------------------------------------------------------------------------

  _splitAndTrim: Split string by seperator and trim the resulting values

    _splitAndTrim = (str, seperator, limit) ->
      r = str.split seperator, limit
      oj._map r, (v) -> v.trim()

  _dasherize: Convert from camal case or space seperated to dashes

    _dasherize = (str) ->
      _decamelize(str).replace /[ _]/g, '-'

  _decamelize: Convert from camal case to underscore case

    _decamelize = (str) ->
      str.replace(/([a-z])([A-Z])/g, '$1_$2').toLowerCase()

Path Helpers
------------------------------------------------------------------------------
Used to implement require client side. These methods are simplified versions of
the node `path` library: github.com/joyent/node/lib/path.js

    _pathSplitRe = /^(\/?)([\s\S]+\/(?!$)|\/)?((?:\.{1,2}$|[\s\S]+?)?(\.[^.\/]*)?)$/
    _pathSplit = (filename) ->
      result = _pathSplitRe.exec filename
      [result[1] or '', result[2] or '', result[3] or '', result[4] or '']
    _pathNormalizeArray = (parts, allowAboveRoot) ->
      up = 0
      i = parts.length - 1
      while i >= 0
        last = parts[i]
        if last == '.'
          parts.splice i, 1
        else if last == '..'
          parts.splice i, 1
          up++
        else if up
          parts.splice i, 1
          up--
        i--
      if allowAboveRoot
        while up--
          parts.unshift '..'
      parts

    oj._pathResolve = ->
      resolvedPath = ''
      resolvedAbsolute = false
      i = arguments.length-1
      while i >= -1 and !resolvedAbsolute
        path = if (i >= 0) then arguments[i] else process.cwd()
        if (typeof path != 'string') or !path
          continue
        resolvedPath = path + '/' + resolvedPath
        resolvedAbsolute = path.charAt(0) == '/'
        i--
      resolvedPath = _pathNormalizeArray(resolvedPath.split('/').filter((p) ->
        return !!p
      ), !resolvedAbsolute).join('/')

      ((if resolvedAbsolute then '/' else '') + resolvedPath) or '.'

    oj._pathNormalize = (path) ->
      isAbsolute = path.charAt(0) == '/'
      trailingSlash = path.substr(-1) == '/'
      path = _pathNormalizeArray(path.split('/').filter((p) ->
        !!p
      ), !isAbsolute).join('/')
      if !path and !isAbsolute
        path = '.'
      if path and trailingSlash
        path += '/'
      (if isAbsolute then '/' else '') + path

    oj._pathJoin = ->
      paths = ArrayP.slice.call arguments, 0
      oj._pathNormalize(paths.filter((p, index) ->
        p and typeof p == 'string'
      ).join('/'))

    oj._pathDirname = (path) ->
      result = _pathSplit path
      root = result[0]
      dir = result[1]
      if !root and !dir
        return '.'
      if dir
        dir = dir.substr 0, dir.length - 1
      root + dir

oj.dependency
------------------------------------------------------------------------------
Ensure dependencies through oj plugins

    oj.dependency = (name, check) ->
      check ?= ->
        if oj.isClient then oj.isDefined(window[name]) else oj.isDefined(global[name])
      throw new Error("oj: #{name} dependency is missing") unless check()

oj.addMethod
------------------------------------------------------------------------------
Add multiple methods to an object

    oj.addMethods = (obj, mapNameToMethod) ->
      for methodName, method of mapNameToMethod
        oj.addMethod obj, methodName, method
      return

oj.addMethod
------------------------------------------------------------------------------
Add method to an object

    oj.addMethod = (obj, methodName, method) ->

  Validate input

      # throw 'oj.addMethod: object expected for first argument' unless oj.isObject obj
      throw 'oj.addMethod: string expected for second argument' unless oj.isString methodName
      throw 'oj.addMethod: function expected for thrid argument' unless oj.isFunction method

  Methods are non-enumerable, non-writable properties

      Object.defineProperty obj, methodName,
        value: method
        enumerable: false
        writable: false
        configurable: true
      return

oj.removeMethod
------------------------------------------------------------------------------
Remove a method from an object

    oj.removeMethod = (obj, methodName) ->

  Validate inputs

      throw 'oj.removeMethod: string expected for second argument' unless oj.isString methodName

  Remove the method
      delete obj[methodName]
      return

oj.addProperties
------------------------------------------------------------------------------
Add multiple properties to an object

Properties can be specified by get/set methods or by a value

Value Property:
`age: 7    # defaults to {writable:true, enumerable:true}`

Value Property with specified writable/enumerable:
`age: {value:7, writable:false, enumerable:false}`

Readonly Get Property
`age: {get:(-> 7)}`

    oj.addProperties = (obj, mapNameToInfo) ->

  Iterate over properties

      for propName, propInfo of mapNameToInfo

  Wrap the value if propInfo is not already a property definition

        if not propInfo?.get? and not propInfo?.value?
          propInfo = value: propInfo, writable:true

        oj.addProperty obj, propName, propInfo

      return

oj.addProperty
------------------------------------------------------------------------------

    oj.addProperty = (obj, propName, propInfo) ->

Validate input

      # throw new Error('oj.addProperty: obj expected for first argument') unless oj.isObject obj

      throw new Error('oj.addProperty: string expected for second argument') unless oj.isString propName

      throw new Error('oj.addProperty: object expected for third argument') unless oj.isObject propInfo


Default properties to enumerable and configurable

      _defaults propInfo,
        enumerable: true
        configurable: true

Remove property if it already exists

      if Object.getOwnPropertyDescriptor(obj, propName)?
        oj.removeProperty obj, propName

Add the property

      Object.defineProperty obj, propName, propInfo
      return

oj.removeProperty
------------------------------------------------------------------------------

    oj.removeProperty = (obj, propName) ->

Validate input

      throw new Error('oj.addProperty: string expected for second argument') unless oj.isString propName

Remove property

      delete obj[propName]

oj.isProperty
------------------------------------------------------------------------------

    # Determine if the specified key is was defined by addProperty

    oj.isProperty = (obj, propName) ->
      throw new Error('oj.isProperty: string expected for second argument') unless oj.isString propName

      Object.getOwnPropertyDescriptor(obj, propName).get?

oj.copyProperty
------------------------------------------------------------------------------
Determine copy source.propName to dest.propName

    oj.copyProperty = (dest, source, propName) ->
      info = Object.getOwnPropertyDescriptor source, propName
      if info.value?
        info.value = _clone info.value
      Object.defineProperty dest, propName, info

_argsStack
------------------------------------------------------------------------------
Abstraction to wrap global arguments stack. This makes me sad but it is necessary for div -> syntax

  Stack of results

    _argsStack = []

  Result is top of the stack

    oj._argsTop = ->
      if _argsStack.length
        _argsStack[_argsStack.length-1]
      else
        null

  Push scope onto arguments

    oj._argsPush = (args = []) ->
      _argsStack.push args
      return

  Pop scope from arguments

    oj._argsPop = ->
      if _argsStack.length
        return _argsStack.pop()
      null

  Append argument

    oj._argsAppend = (arg) ->
      top = oj._argsTop()
      top?.push arg
      return

oj.tag (name, attributes, content, content, ...)
------------------------------------------------------------------------------

    oj.tag = (name, rest...) ->

*name*: String of tag to serialize
*attributes*: (Optional) Object defining attributes of tag being serialized

Styles have smart mappings:

`c`  will map to `class`
`fontSize` will map to `font-size`
`borderRadius` will map to `moz-border-radius`, etc.

  Validate input

      throw 'oj.tag error: argument 1 is not a string (expected tag name)' unless oj.isString name

  Build ojml starting with tag

      ojml = [name]

  Get attributes from rest by unioning all objects

      {args, options:attributes} = oj.unionArguments rest

      if isQuiet = attributes.__quiet__
        delete attributes.__quiet__

  Add attributes to ojml if they exist

      ojml.push attributes unless _isEmpty attributes

  Push arguments to build up children tags

      oj._argsPush ojml

  Loop over attributes

      for arg in args
        if oj.isObject arg
          continue

        else if oj.isFunction arg
          len = oj._argsTop().length

  Call the argument it will auto append to oj._argsTop() which is ojml

          r = arg()

  Use return value if oj._argsTop() weren't changed

          if len == oj._argsTop().length and r?
            oj._argsAppend r

        else
          oj._argsAppend arg

  Pop to restore previous context

      oj._argsPop()

  Append the final result to your parent's arguments
  if there exists an argument to append to.
  Do not emit when quiet is set,

      oj._argsAppend(ojml) unless isQuiet

      ojml

  Define all elements as closed or open

    oj.tag.elements =
      closed: 'a abbr acronym address applet article aside audio b bdo big blockquote body button canvas caption center cite code colgroup command datalist dd del details dfn dir div dl dt em embed fieldset figcaption figure font footer form frameset h1 h2 h3 h4 h5 h6 head header hgroup html i iframe ins keygen kbd label legend li map mark menu meter nav noframes noscript object ol optgroup option output p pre progress q rp rt ruby s samp script section select small source span strike strong style sub summary sup table tbody td textarea tfoot th thead time title tr tt u ul var video wbr xmp'.split ' '
      open: 'area base br col command css !DOCTYPE embed hr img input keygen link meta param source track wbr'.split ' '

  Keep track of all valid elements

    oj.tag.elements.all = (oj.tag.elements.closed.concat oj.tag.elements.open).sort()

  Determine if an element is closed or open

    oj.tag.isClosed = (tag) ->
      (_indexOf oj.tag.elements.open, tag, true) == -1

  Record tag name on a given tag function

    _setTagName = (tag, name) ->
      if tag?
        tag.tagName = name
      return

  Get a tag name on a given tag function

    _getTagName = (tag) ->
      tag.tagName

  Get quiet tag name

    _getQuietTagName = (tag) ->
      tag + '_'

  Record an oj instance on a given element

    _setInstanceOnElement = (el, inst) ->
      el?.oj = inst
      return

  Get a oj instance on a given element

    _getInstanceOnElement = (el) ->
      if el?.oj?
        el.oj
      else
        null

  Create tag methods for all elements

    for t in oj.tag.elements.all
      do (t) ->

  Tag functions emit by default

        oj[t] = -> oj.tag t, arguments...

  Underscore tag functions do not emit

        qt = _getQuietTagName t
        oj[qt] = -> oj.tag t, {__quiet__:1}, arguments...

  Record the tag name so the OJML syntax can use the function instead of a string

        _setTagName oj[t], t
        _setTagName oj[qt], t

oj.doctype
------------------------------------------------------------------------------
Method to define doctypes based on short names

  Define helper variables

    dhp = 'HTML PUBLIC "-//W3C//DTD HTML 4.01'
    w3 = '"http://www.w3.org/TR/html4/'
    strict5 = 'html'
    strict4 = dhp+'//EN" '+w3+'strict.dtd"'

  Define possible arguments

    _doctypes =
      '5': strict5
      'HTML 5': strict5
      '4': strict4
      'HTML 4.01 Strict': strict4
      'HTML 4.01 Frameset': dhp+' Frameset//EN" '+w3+'frameset.dtd"'
      'HTML 4.01 Transitional': dhp+' Transitional//EN" '+w3+'loose.dtd"'

  Define the method passing through to !DOCTYPE tag function

    oj.doctype = (typeOrValue = '5') ->
      value = _doctypes[typeOrValue] ? typeOrValue
      oj['!DOCTYPE'](value)

oj.extendInto (context)
------------------------------------------------------------------------------
Extend all OJ methods into a context. Common contexts are `global` `window`
Methods that start with _ are not extended

    oj.useGlobally = oj.extendInto = (context = root) ->

      o = {}
      for k,v of oj
        if k[0] != '_' and k != 'extendInto' and k != 'useGlobally'
          o[k] = v

      _extend context, o

oj.compile(options, ojml)
------------------------------------------------------------------------------
Compile ojml into meaningful parts

options:

* html - Compile to html
* dom - Compile to dom
* css - Compile to css
* cssMap - Record css as a javascript object
* styles -- Output css as style tags
* minify - Minify js and css
* ignore:{html:1} - Map of tags to ignore while compiling

Define method

    oj.compile = (options, ojml) ->

  Options is optional

      if not ojml?
        ojml = options
        options = {}

      # Default options to compile everything
      options = _defaults {}, options,
        html: true
        dom: false
        css: false
        cssMap: false
        minify: false
        ignore: {}

      # Always ignore oj and css tags
      _extend options.ignore, oj:1, css:1

      acc = _clone options
      acc.html = if options.html then [] else null    # html accumulator
      acc.dom = if options.dom and document? then (document.createElement 'OJ') else null
      acc.css = if options.css or options.cssMap then {} else null
      acc.indent = ''                                 # indent counter
      acc.types = [] if options.dom                   # remember types if making dom
      acc.tags = {}                                   # remember what tags were used
      _compileAny ojml, acc

      if acc.css?
        pluginCSSMap = _flattenCSSMap acc.css

      # Output cssMap if necessary
      if options.cssMap
        cssMap = pluginCSSMap

      # Generate css if necessary
      if options.css
        css = _cssFromPluginObject pluginCSSMap, minify: options.minify, tags:0

      # Generate HTML if necessary
      if options.html
        html = acc.html.join ''

      # Generate dom if necessary
      if options.dom

        # Remove the <oj> wrapping from the dom element
        dom = acc.dom.childNodes

        # Cleanup inconsistencies of childNodes
        if dom.length?
          # Make dom a real array
          dom = _toArray dom
          # Filter out anything that isn't a dom element
          dom = dom.filter (v) -> oj.isDOM(v)

        # Ensure dom is null if empty
        if dom.length == 0
          dom = null

        # Single elements are returned themselves not as a list
        # Reasoning: The common cases don't have multiple elements <html>,<body>
        # or the complexity doesn't matter because insertion is abstracted for you
        # In short it is easier to check for isArray dom, then isArray dom && dom.length > 0
        else if dom.length == 1
          dom = dom[0]

      out = html:html, dom:dom, css:css, cssMap:cssMap, types:acc.types, tags:acc.tags

      out

_styleFromObject:
-----------------------------------------------------------------------------
Convert object to string form

    #
    #     inline:false      inline:true                inline:false,indent:'\t'
    #     color:red;        color:red;font-size:10px   \tcolor:red;
    #     font-size:10px;                              \tfont-size:10px;
    #

    _styleFromObject = (obj, options = {}) ->

  Default options

      _defaults options,
        inline: true
        indent: ''

  Trailing semi should only exist on when we aren't indenting

      options.semi = !options.inline
      out = ""

  Sort keys to create consistent output

      keys = _keys(obj).sort()

  Support indention and inlining

      indent = options.indent ? ''
      newline = if options.inline then '' else '\n'

      for kFancy,ix in keys

  Add semi if it is not inline or it is not the last key

        semi = if options.semi or ix != keys.length-1 then ";" else ''

  Allow keys to be camal case

        k = _dasherize kFancy

  Collect css result for this key

        out += "#{indent}#{k}:#{obj[kFancy]}#{semi}#{newline}"

      out

_attributesFromObject: Convert object to attribute string
-----------------------------------------------------------------------------
This object has nothing special. No renamed keys, no jquery events. It is
precicely what must be serialized with no adjustment.

    _attributesFromObject = (obj) ->
      # Pass through non objects
      return obj if not oj.isObject obj

      out = ''
      # Serialize attributes in order for consistent output
      space = ''
      for k in _keys(obj).sort()
        v = obj[k]

        # Boolean attributes have no value
        if (v == true)
          out += "#{space}#{k}"

        # Other attributes have a value
        else
          out += "#{space}#{k}=\"#{v}\""

        space = ' '
      out

_flattenCSSMap
-----------------------------------------------------------------------------
Take an OJ object definition of CSS and simplify it to the form:
`'plugin' -> '@media query' -> 'selector' ->'rulesMap'`

This method vastly simplifies `_cssFromPluginObject`

Nested definitions, media definitions and comma definitions are resolved.

    _flattenCSSMap = (cssMap) ->
      flatMap = {}
      for plugin,cssMap_ of cssMap
        _flattenCSSMap_ cssMap_, flatMap, [''], [''], plugin
      flatMap

  Recursive helper with accumulators for flatMap (output)

    _flattenCSSMap_ = (cssMap, flatMapAcc, selectorsAcc, mediasAcc, plugin) ->

  Built in media helpers

      medias =
        'widescreen': 'only screen and (min-width: 1200px)'
        'monitor': '' # Monitor is the default
        'tablet': 'only screen and (min-width: 768px) and (max-width: 959px)'
        'phone': 'only screen and (max-width: 767px)'

      for selector, rules of cssMap

  (1) Recursive Case: Recurse on `rules` when it is an object

        if typeof rules == 'object'

  (1a) Media Query found: Generate the next media queries

          if selector.indexOf('@media') == 0

            selectorsNext = selectorsAcc
            selector = (selector.slice '@media'.length).trim()

  Media queries can be comma seperated

            mediaParts = _splitAndTrim selector, ','

  Substitute convience media query methods

            mediaParts = oj._map mediaParts, (v) ->
              if medias[v]? then medias[v] else v

  Calculate the next media queries

            mediasNext = []
            for mediaOuter in mediasAcc
              for mediaInner in mediaParts

                mediaCur = mediaInner
                if (mediaInner.indexOf '&') == -1 and mediaOuter != ''
                  mediaCur = "& and #{mediaInner}"

                mediasNext.push mediaCur.replace(/&/g, mediaOuter)

  (1b) Selector Found: Generate the next selectors

          else
            mediasNext = mediasAcc

  Selectors can be comma seperated

            selectorParts = _splitAndTrim selector, ','

  Generate the next selectors and substitue `&` when present

            selectorsNext = []
            for selOuter in selectorsAcc
              for selInner in selectorParts

  When `&` is not present just insert in front with a space

                selCur = selInner
                if (selInner.indexOf '&') == -1 and selOuter != ''
                  selCur = "& #{selInner}"

                selectorsNext.push selCur.replace(/&/g, selOuter)

  Recurse through objects after calculating the next selectors


          _flattenCSSMap_ rules, flatMapAcc, selectorsNext, mediasNext, plugin

  (2) Base Case: Record our selector when `rules` is a value

        else
          selectorWithCommas = selectorsAcc.sort().join ','

          mediaWithAnds = mediasAcc.sort().join ','
          mediaWithAnds = "@media " + mediaWithAnds unless mediaWithAnds == ''

  Record the rule deeply in `flatMapAcc`

          _setObject flatMapAcc, plugin, mediaWithAnds, selectorWithCommas, selector, rules

      return

_styleClassFromPlugin:
-----------------------------------------------------------------------------

    _styleClassFromPlugin = (plugin) ->
      "#{plugin}-style"

_styleTagFromMediaObject:
-----------------------------------------------------------------------------

    oj._styleTagFromMediaObject = (plugin, mediaMap, options) ->
      newline = if options?.minify then '' else '\n'
      css = _cssFromMediaObject mediaMap, options
      "<style class=\"#{_styleClassFromPlugin plugin}\">#{newline}#{css}</style>"

_cssFromMediaObject:
-----------------------------------------------------------------------------
Convert css from a flattened rule object. The rule object is of the form:
mediaQuery => selector => rulesObject

Placeholder functions for server side minification

    oj._minifyJS = (js,options) -> js
    oj._minifyCSS = (css,options) -> css

    _cssFromMediaObject = (mediaMap, options = {}) ->

      minify = options.minify ? 0
      tags = options.tags ? 0

  Deterine what output characters are needed

      newline = if minify then '' else '\n'
      space = if minify then '' else ' '
      inline = minify

  Build css for media => selector =>  rules

      css = ''
      for media, selectorMap of mediaMap

  Serialize media query

        if media
          media = media.replace /,/g, ",#{space}"
          css += "#{media}#{space}{#{newline}"

        for selector,styles of selectorMap
          indent = if (!minify) and media then '\t' else ''

  Serialize selector

          selector = selector.replace /,/g, ",#{newline}"
          css += "#{indent}#{selector}#{space}{#{newline}"

  Serialize style rules

          indentRule = if (!minify) then indent + '\t' else indent

          rules = _styleFromObject styles, inline:inline, indent:indentRule
          css += rules + indent + '}' + newline

  End media query

        if media != ''
          css += '}' + newline
      try
        css = oj._minifyCSS css, options
      catch eCSS
        throw new Error "css minification error: #{eCSS.message}\nCould not minify:\n#{css}"

      css

_cssFromPluginObject:
-----------------------------------------------------------------------------
Convert flattened css selectors and rules to a string. Plugin objects are of the form:
pluginName => mediaQuery => selector => rulesObject

Supports nested objections, comma seperated rules, and @media queries

minify:false will output newlines
tags:true will output the css in `<style>` tags

    _cssFromPluginObject = (flatCSSMap, options = {}) ->

      minify = options.minify ? 0
      tags = options.tags ? 0

  Deterine what output characters are needed

      newline = if minify then '' else '\n'
      space = if minify then '' else ' '
      inline = minify

      css = ''
      for plugin, mediaMap of flatCSSMap
        if tags
          css += "<style class=\"#{plugin}-style\">#{newline}"

  Serialize CSS with potential minification

        css += _cssFromMediaObject mediaMap, options

        if tags
          css += "#{newline}</style>#{newline}"

      css

_compileDeeper
-----------------------------------------------------------------------------
Recursive helper for compiling that wraps indention

    _compileDeeper = (method, ojml, options) ->
      i = options.indent
      options.indent += '\t'
      method ojml, options
      options.indent = i

_compileAny
-----------------------------------------------------------------------------
Recursive helper for compiling any type

    # Compile ojml or any type
    pass = ->
    _compileAny = (ojml, options) ->

      switch oj.typeOf ojml

        when 'array'
          _compileTag ojml, options

        # when 'jquery'
        #   options.html?.push ojml.html()
        #   options.dom?.concat ojml.get()

        when 'string'
          options.html?.push ojml
          if ojml.length > 0 and ojml[0] == '<'
            root = document.createElement 'div'
            root.innerHTML = ojml
            els = root.childNodes
            options.dom?.appendChild root
            # for el in els
            #   options.dom?.appendChild el
          else
            options.dom?.appendChild document.createTextNode ojml

        when 'boolean', 'number'
          options.html?.push "#{ojml}"
          options.dom?.appendChild document.createTextNode "#{ojml}"

        when 'function'
          # Wrap function call to allow full oj generation within ojml
          _compileAny (oj ojml), options

        when 'date'
          options.html?.push "#{ojml.toLocaleString()}"
          options.dom?.appendChild document.createTextNode "#{ojml.toLocaleString()}"

        # Do nothing for 'null', 'undefined', 'object'
        when 'null' then break
        when 'undefined' then break
        when 'object' then break

        else
          # OJ type
          if oj.isOJ ojml
            options.types?.push ojml
            options.html?.push ojml.toHTML(options)
            options.dom?.appendChild ojml.toDOM(options)
            if options.css?
              _extend options.css, ojml.toCSSMap(options)

      return

_compileTag
-----------------------------------------------------------------------------
Recursive helper for compiling ojml tags

    _compileTag = (ojml, options) ->

  Empty list compiles to undefined

      return if ojml.length == 0

  Get tag name, allowing the tag parameter to be 'table' (tag name) or table (function) or Table (object)

      tag = ojml[0]
      tagType = typeof tag
      tag = if (tagType == 'function' or tagType == 'object') and _getTagName(tag)? then _getTagName(tag) else tag
      throw new Error('oj.compile: tag name is missing') unless oj.isString(tag) and tag.length > 0

  Record tag as encountered

      options.tags[tag] = true

  Instance oj object if tag is capitalized

      if _isCapitalLetter tag[0]
        return _compileDeeper _compileAny, (new oj[tag] ojml.slice(1)), options

  Gather attributes if present

      attributes = null
      if oj.isObject ojml[1]
        attributes = ojml[1]

  Gather children if present

      children = if attributes then ojml.slice 2 else ojml.slice 1

  Compile to css if requested

      if options.css and tag == 'css'

        # Extend options.css with rules
        for selector,styles of attributes
          options.css['oj'] ?= {}
          options.css['oj'][selector] ?= {}
          _extend options.css['oj'][selector], styles

  Compile DOCTYPE as special case because it is not really an element
  It has attributes with spaces and cannot be created by dom manipulation
  In this way it is HTML generation only.

      if tag == '!DOCTYPE'
        throw new Error('oj.compile: doctype expects string as first argument') unless oj.isString ojml[1]
        if not options.ignore[tag]
          if options.html
            options.html.push "<#{tag} #{ojml[1]}>"
          # options.dom is purposely ignored
        return

      if not options.ignore[tag]

        events = _attributesProcessedForOJ attributes

  Compile to dom if requested

        # Add dom element with attributes
        if options.dom and document?
          # Create element
          el = document.createElement tag

          # Add self to parent
          if oj.isDOMElement options.dom
            options.dom.appendChild el

          # Push ourselves on the dom stack (to handle children)
          options.dom = el

          # Set attributes in sorted order for consistency
          if oj.isObject attributes
            for attrName in _keys(attributes).sort()
              attrValue = attributes[attrName]
              # Boolean attributes have no value
              if attrValue == true
                att = document.createAttribute attrName
                el.setAttributeNode att
              else
                el.setAttribute attrName, attrValue

          # Bind events
          _attributesBindEventsToDOM events, el

  Compile to html if requested

        # Add tag with attributes
        if options.html
          attr = (_attributesFromObject attributes) ? ''
          space = if attr == '' then '' else ' '
          options.html.push "<#{tag}#{space}#{attr}>"

  Recurse through children if this tag isn't ignored deeply

      if options.ignore[tag] != 'deep'
        for child in children
          # Skip indention if there is only one child
          if !options.minify and children.length > 1
            options.html?.push "\n\t#{options.indent}"
          _compileDeeper _compileAny, child, options

      # Skip indention if there is only one child
      if (!options.minify) and children.length > 1
        options.html?.push "\n#{options.indent}"

  End html tag if you have children or your tag closes

      if not options.ignore[tag]
        # Close tag if html
        if options.html and (children.length > 0 or oj.tag.isClosed(tag))
          options.html?.push "</#{tag}>"
        # Pop ourselves if dom
        if options.dom
          options.dom = options.dom.parentNode

      return

    # Allow attributes to take style as an object
    _attributeStyleAllowsObject = (attr) ->
      if oj.isObject attr?.style
        attr.style = _styleFromObject attr.style, inline:true
      return

    # Allow attributes to alias c to class and use arrays instead of space seperated strings
    _attributeCMeansClassAndAllowsArrays = (attr) ->
      # Convert to c and class from arrays to strings
      if oj.isArray(attr?.c)
        attr.c = attr.c.join ' '
      if oj.isArray(attr?.class)
        attr.class = attr.class.join ' '

      # Move c to class
      if attr?.c?
        if attr?.class?
          attr.class += ' ' + attr.c
        else
          attr.class = attr.c
        delete attr.c
      return

    # Omit falsy values except for zero
    _attributeOmitFalsyValues = (attr) ->
      if oj.isObject attr
        # Filter out falsy except for 0
        for k,v of attr
          delete attr[k] if v == null or v == undefined or v == false

    # Supported events from jquery
    jqueryEvents = bind:1, on:1, off:1, live:1, blur:1, change:1, click:1, dblclick:1, focus:1, focusin:1, focusout:1, hover:1, keydown:1, keypress:1, keyup:1, mousedown:1, mouseenter:1, mouseleave:1, mousemove:1, mouseout:1, mouseup:1, ready:1, resize:1, scroll:1, select:1

    # Filter out jquery events
    _attributesFilterOutEvents = (attr) ->
      out = {}
      if oj.isObject attr
        # Filter out attributes that are jqueryEvents
        for k,v of attr
          # If this attribute (k) is an event
          if jqueryEvents[k]?
            out[k] = v
            delete attr[k]
      out

    # All the OJ magic for attributes
    _attributesProcessedForOJ = (attr) ->

      # Alias c to class
      _attributeCMeansClassAndAllowsArrays attr

      # style takes objects
      _attributeStyleAllowsObject attr

      # Omit keys that false, null, or undefined
      _attributeOmitFalsyValues attr

      # Filter out jquery events
      events = _attributesFilterOutEvents attr

      # Returns bindable events
      events

    # Bind events to dom
    _attributesBindEventsToDOM = (events, el) ->
      for ek, ev of events
        if oj.$?
          if oj.isArray ev
            oj.$(el)[ek].apply @, ev
          else
            oj.$(el)[ek](ev)
        else
          console.error "oj: jquery is missing when binding a '#{ek}' event"

oj.toHTML
-------------------------------------------------------------------------------
Make ojml directly to HTML ignoring event bindings and css.

    oj.toHTML = (options, ojml) ->
      # Options is optional
      if not oj.isObject options
        ojml = options
        options = {}

      # Create html only
      _extend options, dom:0, js:0, html:1, css:0
      (oj.compile options, ojml).html

oj.toCSS
-------------------------------------------------------------------------------
Compile ojml directly to css ignoring event bindings and html.

    oj.toCSS = (options, ojml) ->
      # Options is optional
      if not oj.isObject options
        ojml = options
        options = {}

      # Create css only
      _extend options, dom:0, js:0, html:0, css:1
      (oj.compile options, ojml).css

    # _inherit
    # ------------------------------------------------------------------------------
    # Based on, but sadly incompatable with, coffeescript inheritance
    _inherit = (child, parent) ->

      # Copy class properties and methods
      for key of parent
        oj.copyProperty child, parent, key

      ctor = ->
      ctor:: = parent::
      child:: = new ctor()

      # Provide easy access for base class methods
      # Example: Parent.base.methodName(arguments...)
      child.base = parent::

      return

    # oj.argumentShift
    # ------------------------------------------------------------------------------
    # Helper to make argument handling easier

    oj.argumentShift = (args, key) ->
      if (oj.isObject args) and key? and args[key]?
        value = args[key]
        delete args[key]
      value

oj.createType
------------------------------------------------------------------------------

    oj.createType = (name, args = {}) ->
      throw 'oj.createType: string expected for first argument' unless oj.isString name
      throw 'oj.createType: object expected for second argument' unless oj.isObject args

      args.methods ?= {}
      args.properties ?= {}

      # When auto newing you need to delay construct the properties
      # or they will be constructed twice.
      delay = '__DELAYED__'
      Out = new Function("""return function #{name}(){
        var _this = this;
        if ( !(this instanceof #{name}) ) {
          _this = new #{name}('#{delay}');
          _this.__autonew__ = true;
        }

        if (arguments && arguments[0] != '#{delay}')
          #{name}.prototype.constructor.apply(_this, arguments);

        return _this;
      }
      """
      )();

      # Default the constructor to call its base
      if args.base? and ((not args.constructor?) or (not args.hasOwnProperty('constructor')))
        args.constructor = ->
          Out.base?.constructor.apply @, arguments

      # Inherit if necessary
      if args.base?
        _inherit Out, args.base

      # Add the constructor as a method
      oj.addMethod Out::, 'constructor', args.constructor

      # Mark new type and its instances with a non-enumerable type and isOJ properties
      typeProps =
        type: {value:Out, writable:false, enumerable:false}
        typeName: {value:name, writable:false, enumerable:false}
        isOJ: {value:true, writable:false, enumerable:false}
      oj.addProperties Out, typeProps
      oj.addProperties Out::, typeProps

      # Add properties helper to instance
      propKeys = (_keys args.properties).sort()
      if Out::properties?
        propKeys = _uniqueSortedUnion Out::properties, propKeys
      properties = value:propKeys, writable:false, enumerable:false
      # propKeys.has = _reduce propKeys, ((o,item) -> o[item.key] = true; o), {}
      oj.addProperty Out::, 'properties', properties

      # Add methods helper to instance
      methodKeys = (_keys args.methods).sort()
      if Out::methods?
        methodKeys = _uniqueSortedUnion Out::methods, methodKeys
      methods = value:methodKeys, writable:false, enumerable:false
      # methodKeys.has = _reduce methodKeys, ((o,item) -> o[item.key] = true; o), {}
      oj.addProperty Out::, 'methods', methods

      # Add methods to the type
      _extend args.methods,

        # get: Get all properties, or get a single property
        get: (k) ->
          if oj.isString k
            if @has k
              return @[k]
            else
              return undefined
          else
            out = {}
            for p in @properties
              out[p] = @[p]
            out

        # set: Set all properties on the object at once
        set: (k,v) ->
          obj = k
          # Optionally take key, value instead of object
          if not oj.isObject k
            obj = {}
            obj[k] = v;

          # Set all keys that are valid properties
          for key,value of obj
            if @has key
              @[key] = value
          return

        # has: Determine if property exists
        has: (k) ->
          _some @properties, (v) -> v == k

        # can: Determine if method exists
        can: (k) ->
          _some @methods, (v) -> v == k

        # toJSON: Use properties to generate json
        toJSON: ->
          json = {}
          for prop in @properties
            json[prop] = @[prop]
          json

      # Add methods
      oj.addMethods Out::, args.methods

      # Add the properties
      oj.addProperties Out::, args.properties

      Out

    # unionArguments:
    # Take arguments and tranform them into options and args.
    # options is a union of all items in `arguments` that are objects
    # args is a concat of all arguments that aren't objects in the same order
    oj.unionArguments = (argList) ->
      options = {}
      args = []
      for v in argList
        if oj.isObject v
          options = _extend options, v
        else
          args.push v
      options: options, args: args

oj.enum
------------------------------------------------------------------------

    oj.enum = (name, args) ->
      throw 'NYI'

oj.View
------------------------------------------------------------------------------

    oj.View = oj.createType 'View',

      # Views are special objects map properties together. This is a union of arguments
      # With the remaining arguments becoming a list

      constructor: (options = {}) ->
        # console.log "View.constructor: ", JSON.stringify arguments

        throw new Error("oj.#{@typeName}: constructor failed to set this.el") unless oj.isDOM @el

        # Set instance on @el
        _setInstanceOnElement @el, @

        # Emit as a tag if new wasn't called
        @emit() if @.__autonew__

        # Generate id if missing
        options.id ?= oj.id()

        # Add class oj-typeName
        @$el.addClass "oj-#{@typeName}"

        # Views automatically set all options to their properties
        # arguments directly to properties
        @set options

        # Remove options that were set
        options = _omit options, @properties...

        # Views pass through remaining options to be attributes on the root element
        # This can include jquery events and interpreted arguments
        @addAttributes options

        # Record if view is fully constructed
        @_isConstructed = true

      properties:

        # The element backing the View
        el:
          get: -> @_el
          set: (v) ->
            # Set the element directly if this is a dom element
            if oj.isDOMElement v
              @_el = v
              # Clear cache of $el
              @_$el = null
            # Generate the element from ojml
            else
              {dom:@_el} = oj.compile css:0, cssMap:0, dom:1, html:0, v
            return

        # Get and cache jquery-enabled element (readonly)
        $el: get: -> @_$el ? (@_$el = oj.$ @el)

        # Get and set id attribute of view
        id:
          get: -> @$el.attr 'id'
          set: (v) -> @$el.attr 'id', v

        # # Get and set class attribute of view
        # class:
        #   get: -> @$el.attr 'class'
        #   set: (v) ->
        #     # Join arrays with spaces
        #     if oj.isArray v
        #       v = v.join ' '
        #     @$el.attr 'class', v
        #     return

        # # Alias for class
        # c:
        #   get: -> @class
        #   set: (v) -> @class = v; return

        # Get all currently set attributes (readonly)
        attributes: get: ->
          out = {}
          oj.$.each @el.attributes, (index, attr) -> out[ attr.name ] = attr.value;
          out

        # Get all currently set themes (readwrite)
        themes: get: ->
          out = {}
          oj.$.each @el.attributes, (index, attr) -> out[ attr.name ] = attr.value;
          out

        # Determine if this view has been fully constructed (readonly)
        isConstructed: get: -> @_isConstructed ? false

        # Determine if this view has been fully inserted (readonly)
        isInserted:
          get: -> @_isInserted ? false

      methods:

        # Mirror backbone view's find by selector
        $: -> @$el.find arguments...

        # Add a single attribute
        addAttribute: (name,value) ->
          attr = {}
          attr[name] = value
          @addAttributes attr
          return

        # Add attributes and apply the oj magic with jquery binding
        addAttributes: (attributes) ->
          attr = _clone attributes

          events = _attributesProcessedForOJ attr

          # Add attributes as object
          if oj.isObject attr
            for k,v of attr
              if k == 'class'
                @addClass v

              # Boolean attributes have no value
              else if v == true
                att = document.createAttribute k
                @el.setAttributeNode att

              # Otherwise add it normally
              else
                @$el.attr k, v

          # Bind events
          if events?
            _attributesBindEventsToDOM events, @el
          return

        # Remove a single attribute
        removeAttribute: (name) ->
          @$el.removeAttr name
          return

        # Remove multiple attributes
        removeAttributes: (list) ->
          for k in list
            @removeAttribute k
          return

        # Add a single class
        addClass: (name) ->
          @$el.addClass name
          return

        # Remove a single class
        removeClass: (name) ->
          @$el.removeClass name
          return

        # Add a single theme
        addTheme: (name) ->
          @addClass "theme-#{name}"
          return

        # Remove a single theme
        removeTheme: (name) ->
          @removeClass "theme-#{name}"
          return

        # Clear all themes
        clearThemes: (name) ->
          @$el.removeClass "theme-#{name}"
          classes = @$el.attr('class').split(' ')
          _each classes, (v) ->
          return

        # emit: Emit instance as a tag function would do
        emit: -> oj._argsAppend @; return

        # Convert View to html
        toHTML: (options) ->
          @el.outerHTML + (if options?.minify then '' else '\n')

        # Convert View to dom (for compiling)
        toDOM: -> @el

        # Convert
        toCSS: (options) -> _cssFromPluginObject (_flattenCSSMap @cssMap), _extend({}, minify:options.minify, tags:0)

        # Convert
        toCSSMap: -> @type.cssMap

        # Convert View to string (for debugging)
        toString: -> @toHTML()

        # # Detach element from dom
        # detach: -> throw 'detach nyi'
        #   # The implementation is to set el manipulate it, and remember how to set it back

        # # Attach element to dom where it use to be
        # attach: -> throw 'attach nyi'
        #   # The implementation is to unset el from detach

        # inserted is called the instance is inserted in the dom (override)
        inserted: ->
          @_isInserted = true

  oj.View.css: set view's css with css object mapping, or raw css string

    oj.View.css = (css) ->
      throw new Error("oj.#{@typeName}.css: object or string expected for first argument") unless oj.isString(css) or oj.isObject(css)
      if oj.isString css
        @cssMap["oj-#{@typeName}"] ?= ""
        @cssMap["oj-#{@typeName}"] += css
      else
        @cssMap["oj-#{@typeName}"] ?= {}
        cssMap = _setObject {}, ".oj-#{@typeName}", css
        _extend @cssMap["oj-#{@typeName}"], cssMap
      return

  oj.View.theme: create a View specific theme with css object mapping

    oj.View.theme = (name, css) ->
      throw new Error("oj.#{@typeName}.theme: string expected for first argument (theme name)") unless oj.isString name
      throw new Error("oj.#{@typeName}.css: object expected for second argument") unless oj.isObject(css)

      @cssMap["oj-#{@typeName}"] ?= {}
      dashName = _dasherize name
      cssMap = _setObject {}, ".oj-#{@typeName}.theme-#{dashName}", css
      _extend @cssMap["oj-#{@typeName}"], cssMap
      @themes.push dashName
      return

    oj.View.cssMap = {}
    oj.View.themes = []

oj.CollectionView
------------------------------------------------------------------------------

    oj.CollectionView = oj.createType 'CollectionView',
      base: oj.View

      constructor: (options) ->
        # console.log "CollectionView constructor: ", arguments

        @each = oj.argumentShift options, 'each' if options?.each?
        @models = oj.argumentShift options, 'models' if options?.models?

        oj.CollectionView.base.constructor.apply @, arguments

        # Once everything is constructed call make precisely once.
        @make()

      properties:

        each:
          get: -> @_each
          set: (v) ->
            @_each = v;
            @make() if @isConstructed
            return

        collection:
          get: -> @models
          set: (v) -> @models = v

        models:
          get: -> @_models
          set: (v) ->
            # Unbind events if collection
            if oj.isFunction @_models?.off
              @_models.off 'add remove change reset destroy', null, @

            @_models = v

            # Bind events if collection
            if oj.isFunction @_models?.on
              @_models.on 'add', @collectionModelAdded, @
              @_models.on 'remove', @collectionModelRemoved, @
              @_models.on 'change', @collectionModelChanged, @
              @_models.on 'destroy', @collectionModelDestroyed, @
              @_models.on 'reset', @collectionReset, @

            @make() if @isConstructed

            return

      methods:
        # Override make to create your view
        make: -> throw new Error("oj.#{@typeName}: `make` method not implemented by custom view")

        # Override these events to minimally update on change
        collectionModelAdded: (model, collection) -> @make()
        collectionModelRemoved: (model, collection, options) -> @make()
        collectionModelChanged: (model, collection, options) -> # Do nothing
        collectionModelDestroyed: (collection, options) -> @make()
        collectionReset: (collection, options) -> @make()

oj.ModelView
------------------------------------------------------------------------------
Model view base class

    oj.ModelView = oj.createType 'ModelView',
      base: oj.View

      constructor: (options) ->

        @value = oj.argumentShift options, 'value' if options?.value?
        @model = oj.argumentShift options, 'model' if options?.model?

        oj.ModelView.base.constructor.apply @, arguments

      properties:

        model:
          get: -> @_model
          set: (v) ->
            # Unbind events on the old model
            if oj.isEvent @_model
              @_model.off 'change', null, @

            @_model = v;

            # Bind events on the new model
            if oj.isEvent @_model
              @_model.on 'change', @modelChanged, @

            # Trigger change manually when settings new model
            @modelChanged()
            return

      methods:

        # Override modelChanged if you don't want a full remake
        modelChanged: ->
          @$el.oj =>
            @make @mode

        make: (model) -> throw "oj.#{@typeName}: `make` method not implemented on custom view"

oj.ModelKeyView
------------------------------------------------------------------------------
Model key view base class

    oj.ModelKeyView = oj.createType 'ModelKeyView',
      # Inherit ModelView to handle model and bindings
      base: oj.ModelView

      constructor: (options) ->
        # console.log "ModelKeyView.constructor: ", JSON.stringify arguments
        @key = oj.argumentShift options, 'key' if options?.key?

        # Call super to bind model and value
        oj.ModelKeyView.base.constructor.apply @, arguments

      properties:
        # Key used to access model
        key: null

        # Value directly gets and sets to the dom
        # when it changes it must trigger viewChanged
        value:
          get: -> throw "#{@typeName} value getter not implemented"
          set: (v) -> throw "#{@typeName} value setter not implemented"

      methods:
        # When the model changes update the value
        modelChanged: ->
          if @model? and @key?
            # Update the view if necessary
            if not @_viewUpdatedModel
              @value = @model.get @key
          return

        # When the view changes update the model
        viewChanged: ->
          # Delay view changes because many of them hook before controls update
          setTimeout (=>
            if @model? and @key?
              # Ensure view changes aren't triggered twice
              @_viewUpdatedModel = true
              @model.set @key, @value
              @_viewUpdatedModel = false
            return
            ), 10
          return

oj.TextBox
------------------------------------------------------------------------------
TextBox control

    oj.TextBox = oj.createType 'TextBox',

      base: oj.ModelKeyView

      constructor: ->
        {options, args} = oj.unionArguments arguments

        @el = oj =>
          oj.input type:'text',
            # Delay change event slighty as value is updated after key presses
            keydown: => if @live then setTimeout((=> @$el.change()),10); return
            keyup: => if @live then setTimeout((=> @$el.change()),10); return
            change: => @viewChanged(); return

        # Value can be set by argument
        @value = args[0] if args.length > 0

        # Set live if it exists
        @live = oj.argumentShift options, 'live' if options?.live?

        oj.TextBox.base.constructor.apply @, [options]

      properties:
        value:
          get: ->
            v = @el.value
            v = '' if not v? or v == 'undefined'
            v
          set: (v) ->
            @el.value = v; return

        # Live update model as text changes
        live: true

oj.CheckBox
------------------------------------------------------------------------------
CheckBox control

    oj.CheckBox = oj.createType 'CheckBox',
      base: oj.ModelKeyView

      constructor: ->
        {options, args} = oj.unionArguments arguments

        @el = oj =>
          oj.input type:'checkbox',
            change: => @viewChanged(); return

        # Value can be set by argument
        @value = args[0] if args.length > 0

        oj.CheckBox.base.constructor.call @, options

      properties:
        value:
          get: -> @el.checked
          set: (v) ->
            v = !!v
            @el.checked = v
            if v
              @$el.attr 'checked', 'checked'
            else
              @$el.removeAttr 'checked'
            return

oj.Text
------------------------------------------------------------------------------
Text control

    oj.Text = oj.createType 'Text',
      base: oj.ModelKeyView

      constructor: ->
        {options, args} = oj.unionArguments arguments

        # Get tag name if provided
        @_tagName = oj.argumentShift options, 'tagName'

        @el = oj =>
          oj[@tagName]()

        # Value can be set by argument
        @value = args[0] if args.length > 0

        oj.Text.base.constructor.call @, options

      properties:

value: text value of this object (readwrite)

        value:
          get: -> @$el.ojValue()
          set: (v) -> @$el.oj(v); return

tagName: name of root tag (writeonce)

        tagName: get: -> @_tagName ? 'div'

oj.TextArea
------------------------------------------------------------------------------
TextArea control

    oj.TextArea = oj.createType 'TextArea',
      base: oj.ModelKeyView

      constructor: ->
        {options, args} = oj.unionArguments arguments

        @el = oj =>
          oj.textarea
            # Delay change event slighty as value is updated after key presses
            keydown: => if @live then setTimeout((=> @$el.change()),10); return
            keyup: => if @live then setTimeout((=> @$el.change()),10); return
            change: => @viewChanged(); return

        # Value can be set by argument
        @value = oj.argumentShift(options, 'value') || args.join('\n');

        oj.TextArea.base.constructor.call @, options

      properties:
        value:
          get: -> @el.value
          set: (v) -> @el.value = v; return

        # Live update model as text changes
        live: true

oj.ListBox
------------------------------------------------------------------------------
ListBox control

    oj.ListBox = oj.createType 'ListBox',
      base: oj.ModelKeyView

      constructor: ->
        {options, args} = oj.unionArguments arguments

        @el = oj =>
          oj.select change: => @viewChanged(); return

        # @options is a list of elements
        @options = oj.argumentShift options, 'options'

        # Value can be set by argument
        @value = args[0] if args.length > 0

        oj.ListBox.base.constructor.apply @, [options]

      properties:
        value:
          get: -> @$el.val()
          set: (v) -> @$el.val(v); return

        options:
          get: -> @_options
          set: (v) ->
            throw new Error("oj.#{@typeName}.options array is missing") unless oj.isArray v
            @_options = v
            @$el.oj ->
              for op in v
                oj.option op
              return
            return

oj.Button
------------------------------------------------------------------------------
Button control

    oj.Button = oj.createType 'Button',
      base: oj.View

      constructor: ->
        {options, args} = oj.unionArguments arguments

        # Label is first argument
        title = ''
        if args.length > 0
          title = args[0]

        # Label is specified as option
        if options.title?
          title = oj.argumentShift(options, 'title')

        @el = oj =>
          oj.button(title)

        oj.Button.base.constructor.apply @, [options]
        @title = title
      properties:
        title:
          get: -> @_title ? ''
          set: (v) -> @$el.oj (@_title = v); return

      methods:
        click: ->
          if arguments.length > 0
            @$el.click(arguments...)
          else
            @$el.click()

oj.Link
------------------------------------------------------------------------------
oj.Link = class Link inherits Control

oj.List
------------------------------------------------------------------------------
List control with model bindings and live editing

    oj.List = oj.createType 'List',
      base: oj.CollectionView

      constructor: ->
        # console.log "List constructor: ", arguments
        {options, args} = oj.unionArguments arguments

        # tagName is write-once
        @_tagName = oj.argumentShift options, 'tagName'

        @itemTagName = oj.argumentShift options, 'itemTagName'

        # Generate el
        @el = oj =>
          oj[@tagName]()

        # Use el if it was passed in
        @el = oj.argumentShift(options, 'el') if options.el?

        # Default @each function to pass through values
        options.each ?= (model) ->
          if (oj.isString model) or (oj.isNumber model) or (oj.isBoolean model)
            model
          else
            JSON.stringify model

        # Args have been handled so don't pass them on
        oj.List.base.constructor.apply @, [options]

        # Set @items to options or args if they exist
        items = if args.length > 0 then args else null
        @items = if options.items? then (oj.argumentShift options, 'items') else items

### Properties

      properties:

items: get or set all items at once (readwrite)

        items:
          get: ->

  Used cached items or items as interpreted by ojValues jquery plugin

            return @_items if @_items?
            v = @$items.ojValues()

          set: (v) -> @_items = v; @make(); return

        count: get: -> @$items.length

tagName: name of root tag (writeonce)

        tagName: get: -> @_tagName ? 'div'

itemTagName: name of item tags (readwrite)

        itemTagName:
          get: -> @_itemTagName ? 'div'
          set: (v) -> @_itemTagName = v; @make(); return

$items: list of `<li>` elements (readonly)

        $items: get: -> @_$items ? (@_$items = @$("> #{@itemTagName}"))

### Methods

      methods:

#### Accessor Methods

item: get or set item value at item ix

        item: (ix, ojml) ->
          ix = @_bound ix, @count, ".item: index"
          if ojml?
            @$item(ix).oj ojml
            return
          else
            @$item(ix).ojValue()

$item: `<li>` element for a given item ix. The tag name may change.

        $item: (ix) ->
          ix = @_bound ix, @count, ".$item: index"
          @$items.eq(ix)

#### CollectionView Methods

make: Remake view from property data

        make: ->

  Some properties call make before construction completes

          return unless @isConstructed

  Convert models to views

          views = []
          if @models? and @each?
            models = if oj.isEvent @models then @models.models else @models
            for model in models
              views.push @_itemFromModel model

  Items are already views

          else if @items?
            views = @items

  Render the views

          @$el.oj =>
            for view in views
              @_itemElFromItem view

          @itemsChanged()
          return

#### CollectionView Events

collectionModelAdded: Model add occurred, add the item

        collectionModelAdded: (m, c) ->
          ix = c.indexOf m
          item = @_itemFromModel m
          @add ix, item
          return

collectionModelRemoved: Model remove occured, delete the item

        collectionModelRemoved: (m, c, o) ->
          @remove o.index
          return

collectionModelRemoved: On add

        collectionReset: ->
          @make()
          return

#### Helper Methods

  _itemFromModel: Helper to map model to item

        _itemFromModel: (model) ->
          oj =>
            @each model

  _itemElFromItem: Helper to create itemTagName wrapped item

        _itemElFromItem: (item) ->
          oj[@itemTagName] item

  _bound: Bound index to allow negatives, throw when out of range

        _bound: (ix, count, message) ->
          _boundOrThrow ix,count,message,@typeName

#### Events

itemsChanged: Model changed occured, clear relevant cached values

        itemsChanged: -> @_items = null; @_$items = null; return

#### Manipulation Methods

        add: (ix, ojml) ->

          ix = @_bound ix, @count+1, ".add: index"

          tag = @itemTagName
          # Empty
          if @count == 0
            @$el.oj -> oj[tag] ojml
          # Last
          else if ix == @count
            @$item(ix-1).ojAfter -> oj[tag] ojml
          # Not last
          else
            @$item(ix).ojBefore -> oj[tag] ojml

          @itemsChanged()
          return

        remove: (ix) ->
          ix = @_bound ix, @count, ".remove: index"
          out = @item ix
          @$item(ix).remove()
          @itemsChanged()
          out

        move: (ixFrom, ixTo = -1) ->
          return if ixFrom == ixTo

          ixFrom = @_bound ixFrom, @count, ".move: fromIndex"
          ixTo = @_bound ixTo, @count, ".move: toIndex"

          if ixTo > ixFrom
            @$item(ixFrom).insertAfter @$item(ixTo)
          else
            @$item(ixFrom).insertBefore @$item(ixTo)

          @itemsChanged()
          return

        swap: (ix1, ix2) ->
          return if ix1 == ix2

          ix1 = @_bound ix1, @count, ".swap: firstIndex"
          ix2 = @_bound ix2, @count, ".swap: secondIndex"

          if Math.abs(ix1-ix2) == 1
            @move ix1, ix2
          else
            ixMin = Math.min ix1, ix2
            ixMax = Math.max ix1, ix2
            @move ixMax, ixMin
            @move ixMin+1, ixMax
          @itemsChanged()
          return

        unshift: (v) -> @add 0, v; return

        shift: -> @remove 0

        push: (v) -> @add(@count, v); return

        pop: -> @remove -1

        clear: -> @$items.remove(); @itemsChanged(); return

oj.NumberList
------------------------------------------------------------------------------
NumberList is a `List` specialized with `<ol>` and `<li>` tags

    oj.NumberList = oj.createType 'NumberList',
      base: oj.List
      constructor: ->
        args = [{tagName:'ol', itemTagName:'li'}, arguments...]
        oj.NumberList.base.constructor.apply @, args

oj.BulletList
------------------------------------------------------------------------------
BulletList is a `List` specialized with `<ul>` and `<li>` tags

    oj.BulletList = oj.createType 'BulletList',
      base: oj.List
      constructor: ->
        args = [{tagName:'ul', itemTagName:'li'}, arguments...]
        oj.BulletList.base.constructor.apply @, args

oj.Table
------------------------------------------------------------------------------
Table control

    oj.Table = oj.createType 'Table',

Inherit and construct

      base: oj.CollectionView

      constructor: ->
        # console.log "Table constructor: ", arguments
        {options, args} = oj.unionArguments arguments

        # Generate el
        @el = oj =>
          oj.table()

        # Use el if it was passed in
        @el = oj.argumentShift(options, 'el') if options.el?

        # Default @each function to pass through values
        options.each ?= (model,cell) ->
          values = if (oj.isString model) or (oj.isNumber model) or (oj.isBoolean model)
            [model]
          else if (oj.isEvent model) and typeof model.attributes == 'object'
            _values model.attributes
          else
            _values model
          cell v for v in values

        # Args have been handled so don't pass them on
        oj.Table.base.constructor.apply @, [options]

        # Validate args as arrays
        for arg in args
          unless oj.isArray arg
            throw new Error 'oj.Table: array expected for row arguments'

        # Set @rows to options or args if they exist
        rows = (oj.argumentShift options, 'rows') ? args

        if rows.length > 0
          @rows = rows

### Properties

      properties:

rowCount: The number of rows (readonly)

        rowCount: get: -> @$trs.length

columnCount: The number of columns (readonly)

        columnCount: get: ->
          if (trlen = @$tr(0).find('> td').length) > 0
            trlen
          else if (thlen = @$theadTR.find('> th').length) > 0
            thlen
          else if (tflen = @$tfootTR.find('> td').length) > 0
            tflen
          else
            0

#### Accessor properties

rows: Row values as a list of lists as interpreted by ojValue plugin (readwrite)

        rows:
          get: ->
            return @_rows if @_rows?
            @_rows = []
            for rx in [0...@rowCount] by 1
              r = oj._map (@$tdsRow rx), ($td) -> $td.ojValues()
              @_rows.push r
            @_rows

          set: (list) ->
            return @clearBody() unless list? and list.length > 0
            @_rows = list; @make(); return

header: Array of header values as interpreted by ojValue plugin (readwrite)

        header:
          get: ->
            @$theadTR.find('> th').ojValues()
          set: (list) ->
            throw new Error('oj.Table.header: array expected for first argument') unless oj.isArray list
            return @clearHeader() unless list? and list.length > 0
            @$theadTRMake.oj =>
              for ojml in list
                oj.th ojml

footer: Array of footer values as interpreted by ojValue plugin (readwrite)

        footer:
          get: ->
            @$tfootTR.find('> td').ojValues()
          set: (list) ->
            throw new Error('oj.Table.footer: array expected for first argument') unless oj.isArray list
            return @clearFooter() unless list? and list.length > 0
            @$tfootTRMake.oj =>
              for ojml in list
                oj.td ojml

caption: The table caption (readwrite)

        caption:
          get: -> @$caption.ojValue()
          set: (v) -> @$captionMake.oj v; return

Element accessors

        $table: get: -> @$el

        $caption: get: -> @$ '> caption'

        $colgroup: get: -> @$ '> colgroup'

        $thead: get: -> @$ '> thead'

        $tfoot: get: -> @$ '> tfoot'

        $tbody: get: -> @$ '> tbody'

        $theadTR: get: -> @$thead.find '> tr'

        $tfootTR: get: -> @$tfoot.find '> tr'

        $ths: get: -> @$theadTR.find '> th'

        $trs: get: -> @_$trs ? (@_$trs = @$("> tbody > tr"))

Table tags must have an order: `<caption>` `<colgroup>` `<thead>` `<tfoot>` `<tbody>`
These accessors create table tags and preserve this order very carefully

$colgroupMake: get or create `<colgroup>` after `<caption>` or prepended to `<table>`

        $colgroupMake: get: ->
          return @$colgroup if @$colgroup.length > 0
          t = '<colgroup></colgroup>'
          if @$caption.length > 0
            @$caption.insertAfter t
          else
            @$table.append t
          @$tbody

$captionMake: get or create `<caption>` prepended to `<table>`

        $captionMake: get: ->
          return @$caption if @$caption.length > 0
          @$table.prepend '<caption></caption>'
          @$caption

$tfootMake: get or create `<tfoot>` before `<tbody>` or appended to `<table>`

        $tfootMake: get: ->
          return @$tfoot if @$tfoot.length > 0
          t = '<tfoot></tfoot>'
          if @$tfoot.length > 0
            @$tfoot.insertBefore t
          else
            @$table.append t

          @$tfoot

$theadMake: get or create `<thead>` after `<colgroup>` or after `<caption>`, or prepended to `<table>`

        $theadMake: get: ->
          return @$thead if @$thead.length > 0
          t = '<thead></thead>'
          if @$colgroup.length > 0
            @$colgroup.insertAfter t
          else if @$caption.length > 0
            @$caption.insertAfter t
          else
            @$table.prepend t

          @$thead

$tbodyMake: get or create `<tbody>` appened to `<table>`

        $tbodyMake: get: ->
          return @$tbody if @$tbody.length > 0
          @$table.append '<tbody></tbody>'
          @$tbody

$theadTRMake: get or create `<tr>` inside of `<thead>`

        $theadTRMake: get: ->
          return @$theadTR if @$theadTR.length > 0
          @$theadMake.html '<tr></tr>'
          @$theadTR

$tfootTRMake: get or create `<tr>` inside of `<tfoot>`

        $tfootTRMake: get: ->
          return @$tfootTR if @$tfootTR.length > 0
          @$tfootMake.html '<tr></tr>'
          @$tfootTR

### Methods

      methods:

#### CollectionView Methods

make: Remake everything

        make: ->

  Some properties call make before construction completes

          return unless @isConstructed

  Convert models to views

          rowViews = []
          if @models? and @each?
            models = if oj.isEvent @models then @models.models else @_models
            for model in models
              rowViews.push @_rowFromModel model

  Rows need tds to become views

          else if @rows?
            for row in @rows
              rowViews.push oj ->
                for c in row
                  oj.td c

  Render rows into tbody

          if rowViews.length > 0
            @$tbodyMake.oj =>
              for r in rowViews
                oj.tr r

          @bodyChanged()
          return

#### CollectionView Events

        # On add minimally create the missing model
        collectionModelAdded: (m, c) ->
          rx = c.indexOf m
          row = @_rowFromModel m
          @_addRowTR rx, oj -> oj.tr row
          return

        # On add minimally create the missing model
        collectionModelRemoved: (m, c, o) ->
          @removeRow o.index
          return

        collectionReset: ->
          @make()
          return

#### Accessor Methods

table.header(r,ojml)    // value for header
table.cell(r,c,ojml)    // get/set value for cell

$tr: Get `<tr>` jquery element at row rx

        $tr: (rx) ->
          rx = if rx < 0 then rx + count else rx
          @$trs.eq(rx)

$tdsRow: Get list of `<td>`s in row rx

        $tdsRow: (rx) ->
          rx = if rx < 0 then rx + count else rx
          @$tr(rx).find '> td'

$td: Get `<td>` row rx, column cx

        $td: (rx,cx) ->
          rx = if rx < 0 then rx + @rowCount else rx
          cx = if cx < 0 then cx + @columnCount else cx
          @$tdsRow(rx).eq(cx)

row: Get values at a given row

        row: (rx, listOJML) ->
          rx = @_bound rx, @rowCount, ".row: rx"
          if listOJML?
            throw new Error("oj.#{@typeName}: array expected for second argument with length length cellCount(#{rx})") unless listOJML.length == cellCount(rx)
            for ojml,cx in listOJML
              @$td(rx,cx).oj ojml
            return
          else
            @$tdsRow(rx).ojValues()

cell: Get or set value at row rx, column cx

        cell: (rx, cx, ojml) ->
          if ojml?
            @$td(rx, cx).oj ojml
          else
            @$td(rx, cx).ojValue()

#### Manipulation Methods


addRow: Add row to index rx

        addRow: (rx, listOJML) ->
          throw new Error('oj.addRow: expected two arguments') unless arguments.length == 2

          rx = @_bound rx, @rowCount+1, ".addRow: rx"

          tr =
            ->
              oj.tr ->
                for o in listOJML
                  oj.td o

          @_addRowTR rx, tr
          return

_addRowTR: Helper to add row directly with `<tr>`

        _addRowTR: (rx, tr) ->

          # Empty
          if @rowCount == 0
            @$el.oj tr

          # Last
          else if rx == @rowCount
            @$tr(rx-1).ojAfter tr

          # Not last
          else
            @$tr(rx).ojBefore tr

          @bodyChanged()
          return

removeRow: Remove row at index rx (defaults to end)

        removeRow: (rx) ->
          throw new Error('oj.removeRow: expected one argument') unless arguments.length == 1

          rx = @_bound rx, @rowCount, ".removeRow: index"
          out = @row rx
          @$tr(rx).remove()
          @bodyChanged()
          out

moveRow: Move row at index rx (defaults to end)

        moveRow: (rxFrom, rxTo) ->
          return if rxFrom == rxTo

          rxFrom = @_bound rxFrom, @rowCount, ".moveRow: fromIndex"
          rxTo = @_bound rxTo, @rowCount, ".moveRow: toIndex"

          insert = if rxTo > rxFrom then 'insertAfter' else 'insertBefore'
          @$tr(rxFrom)[insert] @$tr(rxTo)

          @bodyChanged()
          return

swapRow: Swap row rx1 and rx2

        swapRow: (rx1, rx2) ->
          return if rx1 == rx2

          rx1 = @_bound rx1, @rowCount, ".swap: firstIndex"
          rx2 = @_bound rx2, @rowCount, ".swap: secondIndex"

          if Math.abs(rx1-rx2) == 1
            @moveRow rx1, rx2
          else
            rxMin = Math.min rx1, rx2
            rxMax = Math.max rx1, rx2
            @moveRow rxMax, rxMin
            @moveRow rxMin+1, rxMax
          @bodyChanged()
          return

        unshiftRow: (v) -> @addRow(0, v); return
        shiftRow: -> @removeRow 0
        pushRow: (v) -> @addRow(@rowCount, v); return
        popRow: -> @removeRow -1

        clearColgroup: -> @$colgroup.remove(); return

        clearBody: -> @$tbody.remove(); @bodyChanged(); return

        clearHeader: -> @$thead.remove(); @headerChanged(); return

        clearFooter: -> @$tfoot.remove(); @footerChanged(); return

        clearCaption: -> @$capation.remove(); return

        clear: -> @clearBody(); @clearHeader(); @clearFooter(); @$caption.remove()

#### Event Handlers

        # When body changes clear relevant cached values
        bodyChanged: -> @_rows = null; @_columns = null; @_$trs = null; return

        # When header changes clear relevant cached values
        headerChanged: -> @_header = null; return

        # When footer changes clear relevant cached values
        footerChanged: -> @_footer = null; return

#### Helper Methods

_rowFromModel: Helper to map model to row

        _rowFromModel: (model) ->
          oj =>
            @each model, oj.td

_rowElFromItem: Helper to create rowTagName wrapped row

        _rowElFromItem: (row) ->
          oj[@rowTagName] row

  _bound: Bound index to allow negatives, throw when out of range

        _bound: (ix, count, message) ->
          _boundOrThrow ix, count, message, @typeName

oj.sandbox
------------------------------------------------------------------------------
The sandbox is a readonly version of oj that is exposed to the user

    oj.sandbox = {}
    for key in _keys oj
      if key.length > 0 and key[0] != '_'
        oj.addProperty oj.sandbox, key, value:oj[key], writable:false

oj.use(plugin, settings)
------------------------------------------------------------------------------
Include a plugin of OJ with `settings`

    oj.use = (plugin, settings = {}) ->

      # Allow use to extend globally
      if arguments.length == 0
        return oj.useGlobally();

      throw new Error('oj.use: function expected for first argument') unless oj.isFunction plugin
      throw new Error('oj.use: object expected for second argument') unless oj.isObject settings

      # Call plugin to gather extension map
      pluginMap = plugin oj, settings

      # Extend all properties
      for name,value of pluginMap
        oj[name] = value
        # Add to sandbox
        oj.addProperty oj.sandbox, name, value:value, writable: false

_jqueryExtend(fn)
-----------------------------------------------------------------------------

option.get is called to retrieve value per element
option.set is called when setting elements
option.first:true means return only the first get, otherwise it is returned as an array.

    _jqueryExtend = (options = {}) ->
      _defaults options, get:_identity, set:_identity, first: false
      ->
        args = _toArray arguments
        $els = jQuery(@)
        # Map over jquery selection if no arguments
        if (oj.isFunction options.get) and args.length == 0
          out = []
          for el in $els
            out.push options.get oj.$(el)
            if options.first
              return out[0]
          out

        else if (oj.isFunction options.set)
          # By default return this for chaining
          out = $els
          for el in $els
            r = options.set oj.$(el), args
            # Short circuit if anything is returned
            return r if r?

          $els

    _triggerTypes = (types) ->
      for type in types
        type.inserted()
      return

    _insertStyles = (pluginMap, options) ->
      for plugin, mediaMap of pluginMap
        # Skip global css if options.global is true
        continue if plugin == 'oj-style' and not options?.global
        # Create <style> tag for the plugin
        if oj.$('.' + _styleClassFromPlugin plugin).length == 0
          oj.$('head').append oj._styleTagFromMediaObject plugin, mediaMap
      return

jQuery.fn.oj
-----------------------------------------------------------------------------

    oj.$.fn.oj = _jqueryExtend
      set:($el, args) ->

        # No arguments return the first instance
        if args.length == 0
          return $el[0].oj

        # Compile ojml
        `with (oj) {`
        {dom,types,cssMap} = oj.compile {dom:1,html:0,cssMap:1}, args...
        `}`

        _insertStyles cssMap, global:0

        # Reset content and append to dom
        $el.html ''
        dom = [dom] unless oj.isArray dom
        $el.append(d) for d in dom

        _triggerTypes types

        return

      get: ($el) ->
        $el[0].oj

jQuery.ojBody ojml
-----------------------------------------------------------------------------
Replace body with ojml. Global css is rebuild when using this method.

    oj.$.ojBody = (ojml) ->

  Compile only the body and below

      bodyOnly = html:1, '!DOCTYPE':1, body:1, head:'deep', meta:1, title:'deep', link:'deep', script:'deep'

      try
        {dom,types,cssMap} = oj.compile dom:1, html:0, css:0, cssMap:1, ignore:bodyOnly, ojml

      catch eCompile
        throw new Error("oj.compile: #{eCompile.message}")

  Clear body and insert dom elements

      oj.$('body').html(dom) if dom?

      _insertStyles cssMap, global:1

      _triggerTypes types

jQuery.fn.ojValue
-----------------------------------------------------------------------------
Get the first value of the selected contents

    _jqGetValue = ($el, args) ->

      el = $el[0]
      child = el.firstChild

      switch oj.typeOf child
        # Parse the text to turn it into bool, number, or string
        when 'dom-text'
          text = oj.parse child.nodeValue

        # Get elements as oj instances or elements
        when 'dom-element'
          if (inst = _getInstanceOnElement child)?
            inst
          else
            child

    oj.$.fn.ojValue = _jqueryExtend
      first: true
      set: null
      get: _jqGetValue

jQuery.fn.ojValues
-----------------------------------------------------------------------------
Get values as an array of the selected element's contents

    oj.$.fn.ojValues = _jqueryExtend
      first: false
      set: null
      get: _jqGetValue

jQuery plugins
-----------------------------------------------------------------------------

    plugins =
      ojAfter: 'after'
      ojBefore: 'before'
      ojAppend: 'append'
      ojPrepend: 'prepend'
      ojReplaceWith: 'replaceWith'
      ojWrap: 'wrap'
      ojWrapInner: 'wrapInner'

    for ojName,jqName of plugins
      do (ojName, jqName) ->
        oj.$.fn[ojName] = _jqueryExtend
          set: ($el, args) ->

            # Compile ojml for each one to separate references
            {dom,types,cssMap} = oj.compile {dom:1,html:0,css:0,cssMap:1}, args...

            _insertStyles cssMap, global:0

            # Append to the dom
            $el[jqName] dom

            _triggerTypes types

            return

          get:null
