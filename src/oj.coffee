
# oj
# ==============================================================================
# A unified templating framework for the people. Thirsty people.


# oj function
# ------------------------------------------------------------------------------
# Convert ojml to dom
oj = module.exports = (ojml) ->
  oj.toDOM ojml

# Keep a reference to ourselves for templates to see
oj.oj = oj

# oj.begin
# ------------------------------------------------------------------------------
oj.begin = module.exports = (page) ->
  # Compile
  compiled = oj.compile require page

  # Setup dom
  html = compiled.html

  document.write html

  # Setup jquery events and awaken oj objects
  compiled.js()

  # Setup jquery ready and onload events
  oj.ready()
  oj.load()

# Helpers
# ------------------------------------------------------------------------------
# Loading with either ready or onload
_load = (evt, fn) ->
  if $? and evt == 'ready'
    $(fn)
  else
    # Add onload if it hasn't happened yet
    if document.readyState != "complete"
      prevOnLoad = window.onload
      window.onload = ->
        prevOnLoad?()
        fn()
    # Otherwise call the function
    else
      fn()
  return

# Generalized delay loading
_loaderQueue =
  ready: queue:[], loaded:false
  load: queue:[], loaded:false

_loader = (evt) ->
  (fn) ->
    # Call everything if no arguments
    if _.isUndefined fn
      _loaderQueue[evt].loaded = true
      while (f = _loaderQueue[evt].queue.shift())
        _load evt, f
    # Call load if already loaded
    else if _loaderQueue[evt].loaded
      _load evt, f
    # Queue function for later
    else
      _loaderQueue[evt].queue.push fn
    return

oj.error = (message) ->
  red = oj.codes?.red ? ''
  reset = oj.codes?.red ? ''
  console.error "#{red}#{message}#{reset}"
  return

# ## oj.ready
oj.ready = _loader 'ready'

# ## oj.load
oj.load = _loader 'load'

# ## oj.id
oj.id = (len, chars) ->
  'oj' + oj.guid len, chars

# ## oj.guid
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

# Register require.extension for .oj files in node
if require.extensions

  coffee = require 'coffee-script'
  fs = require new String('fs') # Hack to avoid pulling fs to client

  stripBOM = (c) -> if c.charCodeAt(0) == 0xFEFF then (c.slice 1) else c

  isCS = (code) -> -1 != code.search /(^\s*#|\n\s*#|-\>)/
  isJS = (code) -> -1 != code.search /var|function|((^|\n)\s*\/\/)/

  require.extensions['.oj'] = (module, filepath) ->
    # Compile as coffee-script or javascript
    code = stripBOM fs.readFileSync filepath, 'utf8'

    # Transform into coffee script if necessary
    try
      code = coffee.compile code, bare: true

    catch eCoffee

      eCoffee.message = "#{oj.codes?.red}coffee-script error in #{filepath}: #{eCoffee.message}#{oj.codes?.reset}"
      # Report it as a coffee-script error if we are pretty
      # sure it is
      if (isCS code) or not (isJS code)
        throw eCoffee

    # Compile javascript
    try
      code = "(function(){with(require('oj')){#{code}}}).call(this);"
      module._compile code, filepath

    catch eJS

      eJS.message = "#{oj.codes?.red}javascript error in #{filepath}: #{eJS.message}#{oj.codes?.reset}"
      throw eJS

root = @

oj.version = '0.0.7'

oj.isClient = true

# Export for NodeJS if necessary
if typeof module != 'undefined'
  exports = module.exports = oj
else
  root['oj'] = oj

# Utility: Helpers
# ------------------------------------------------------------------------------

ArrayP = Array.prototype
FuncP = Function.prototype
ObjP = Object.prototype

slice = ArrayP.slice
unshift = ArrayP.unshift

# Methods from [underscore.js](http://underscorejs.org/), because some methods just need to exist.
oj.__ = _ = {}
_.isUndefined = (obj) -> obj == undefined
_.isBoolean = (obj) -> obj == true or obj == false or toString.call(obj) == '[object Boolean]'
_.isNumber = (obj) -> !!(obj == 0 or (obj and obj.toExponential and obj.toFixed))
_.isString = (obj) -> !!(obj == '' or (obj and obj.charCodeAt and obj.substr))
_.isDate = (obj) -> !!(obj and obj.getTimezoneOffset and obj.setUTCFullYear)
_.isRegExp = (obj) -> toString.call(obj) == '[object RegExp]'
_.isFunction = (obj) -> typeof obj == 'function'
_.isArray = Array.isArray or (obj) -> toString.call(obj) == '[object Array]'
_.isElement = (obj) -> !!(obj and obj.nodeType == 1)
_.isCapitalLetter = (c) -> !!(c.match /[A-Z]/)
_.identity = (v) -> v
_.property = (obj, options = {}) ->
  # _.defaults options, configurable: false
  Object.defineProperty obj, options
_.has = (obj, key) -> Object.prototype.hasOwnProperty.call(obj, key)
_.keys = Object.keys || (obj) ->
  throw 'Invalid object' if obj != Object(obj)
  keys = [];
  for key of obj
    if _has obj, key
      keys[keys.length] = key;
  keys
_.values = (obj) ->
  throw 'Invalid object' if obj != Object(obj)
  out = []
  _.each obj, (v) -> out.push v
  out

_.flatten = (array, shallow) ->
  _.reduce array, ((memo, value) ->
    if _.isArray value
      return memo.concat(if shallow then value else _.flatten(value))
    memo[memo.length] = value
    memo
  ), []

_.reduce = (obj = [], iterator, memo, context) ->
  initial = arguments.length > 2
  if ArrayP.reduce and obj.reduce == ArrayP.reduce
    if context
      iterator = _.bind iterator, context
    return if initial then obj.reduce iterator, memo else obj.reduce iterator

  _.each obj, (value, index, list) ->
    if (!initial)
      memo = value
      initial = true
    else
      memo = iterator.call context, memo, value, index, list

  if !initial
    throw new TypeError 'Reduce of empty array with no initial value'
  memo

  ctor = ->
  _.bind = (func, context) ->
    if func.bind == FuncP.bind and FuncP.bind
      return FuncP.bind.apply func, slice.call(arguments, 1)
    throw new TypeError unless _.isFunction(func)
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


_.sortedIndex = (array, obj, iterator = _.identity) ->
  low = 0
  high = array.length;
  while low < high
    mid = (low + high) >> 1;
    if iterator(array[mid]) < iterator(obj) then low = mid + 1 else high = mid;
  low

_.indexOf = (array, item, isSorted) ->
  return -1 unless array?
  if isSorted
    i = _.sortedIndex array, item
    return if array[i] == item then i else -1
  if (ArrayP.indexOf && array.indexOf == ArrayP.indexOf)
    return array.indexOf item
  for v, i in array
    if v == item
      return i
  -1

# _.create
# ------------------------------------------------------------------------------
# Abstract Object.create for older browsers
#
# Define this once to improve performance in older browsers
F = ->
_.create =
  # Check for existing native / shimmed Object.create
  if typeof Object.create == "function"
    # found native/shim, so use it
    Object.create

  # Based on Crockford shim
  else
    (o) ->
      # set the prototype of the function
      # so we will get `o` as the prototype
      # of the new object instance
      F.prototype = o

      # create a new object that inherits from
      # the `o` parameter
      child = new F()

      # clean up just in case o is really large
      F.prototype = null

      # send it back
      child

_.getPrototypeOf =
  if typeof Object.getPrototypeOf == "function"
    Object.getPrototypeOf
  else
    (o) -> o.proto || o.constructor.prototype

# Utility: Type Detection
# -----------------------

# _.isjQuery
_.isjQuery = (obj) -> !!(obj and obj.jquery)

# _.isBackbone
_.isBackbone = (obj) -> !!(obj and obj.on and obj.trigger and not _.isOJ obj)

# oj.isOJ
# Determine if obj is an OJ instance
oj.isOJ = (obj) -> !!(obj?.isOJ)

# Determine if object or array is empty
_.isEmpty = (obj) ->
  return obj.length == 0 if _.isArray obj
  for k of obj
    if _.has obj, k
      return false
  true

# typeOf: Mimic behavior of built-in typeof operator and integrate jQuery, Backbone, and OJ types
oj.typeOf = (any) ->

  return 'null' if any == null
  t = typeof any
  if t == 'object'
    if _.isArray any           then t = 'array'
    else if _.isRegExp any     then t = 'regexp'
    else if _.isDate any       then t = 'date'
    else if _.isBackbone any   then t = 'backbone'
    else if _.isjQuery any     then t = 'jquery'
    else if oj.isOJ any         then t = any.type
    else                       t = 'object'
  t

# Determine if obj is a vanilla object
_.isObject = (obj) -> (oj.typeOf obj) == 'object'

_.clone = (obj) ->
  # TODO: support cloning OJ instances
  # TODO: support options, deep: true
  return obj unless _.isObject obj
  if _.isArray obj then obj.slice() else _.extend {}, obj

oj.enum = (name, args) ->
  throw 'NYI'

# Utility: Iteration
# ------------------------------------------------------------------------

# _each(collection, iterator, context)
#
#     Iterate over collection or function. If a function
#     is encountered it is evaluated before iteration
#
#     collection    Array or Object to iterate over
#     iterator      Function to call on each step
#     context       (Optional) Object to pass as 'this' to iteration method

_.breaker = {}
_.each = (col, iterator, context) ->

  return if col == null
  if ArrayP.forEach and col.forEach == ArrayP.forEach
    col.forEach iterator, context
  else if _.isArray col
    for v, i in col
      if iterator.call(context, v, i, col) == _.breaker
        return _.breaker
  else
    for k, v of col
      if _.has col, k
        if iterator.call(context, v, k, col) == _.breaker
          return _.breaker

# _.map(collection, iterator, options = {})
#
#     Map over object or array If a function
#     is encountered it is evaluated before iteration
#
#     collection    Array or Object to iterate over
#     iterator      Function to call on each step
#     options
#       context       (Optional) Object to pass as 'this' to iteration method
#       context       (Optional) Boolean indicating  to pass as 'this' to iteration method

_.map = (obj, iterator, options = {}) ->

  context = options.context
  recurse = options.recurse
  evaluate = options.evaluate

  # Recurse if necessary
  iterator_ = iterator
  if recurse
    do (options) ->
      iterator_ = (v,k,o) ->
        options_ = _.extend (_.clone options), (key: k, object: v)
        _.map v, iterator, options_

  # Evaluate functions if necessary
  if _.isFunction obj

    # Functions pass through if evaluate isn't set
    return obj unless evaluate

    while evaluate and _.isFunction obj
      obj = obj()

  out = obj

  # Array case
  if _.isArray obj
    out = []
    return out unless obj
    return (obj.map iterator_, context) if ArrayP.map and obj.map == ArrayP.map
    _.each(obj, ((v, ix, list) ->
      out[out.length] = iterator_.call context, v, ix, list
    ))

    if obj.length == +obj.length
      out.length = obj.length

  # Object case
  else if _.isObject obj
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

# _.extend
_.extend = (obj) ->
  _.each(slice.call(arguments, 1), ((source) ->
    for key, value of source
      obj[key] = value
  ))
  obj

# _.defaults
_.defaults = (obj) ->
  _.each(slice.call(arguments, 1), ((source) ->
    for prop of source
      if not obj[prop]?
        obj[prop] = source[prop]
  ))
  obj

_.uniqueSort = (array, isSorted = false) ->
  if not isSorted
    array.sort()
  out = []
  for item,ix in array
    if ix > 0 and array[ix-1] == array[ix]
      continue
    out.push item
  out

_.uniqueSortedUnion = (array, array2) ->
  _.uniqueSort (array.concat array2)


# oj.addMethod
# ------------------------------------------------------------------------------
oj.addMethods = (obj, mapNameToMethod) ->
  for methodName, method of mapNameToMethod
    oj.addMethod obj, methodName, method
  return

# oj.addMethod
# ------------------------------------------------------------------------------
oj.addMethod = (obj, methodName, method) ->
  throw 'oj.addMethod: string expected for second argument' unless _.isString methodName
  throw 'oj.addMethod: function expected for thrid argument' unless _.isFunction method
  Object.defineProperty obj, methodName,
    value: method
    enumerable: false
    writable: false
    configurable: true
  return

# oj.removeMethod
# ------------------------------------------------------------------------------
oj.removeMethod = (obj, methodName) ->
  throw 'oj.removeMethod: string expected for second argument' unless _.isString methodName
  delete obj[methodName]
  return

# oj.addProperties
# ------------------------------------------------------------------------------
oj.addProperties = (obj, mapNameToInfo) ->

  for propName, propInfo of mapNameToInfo
    # Prop value may be specified by an object with a get/set or by value
    # Examples:
    #   age: 7    # defaults to {writable:true, enumerable:true}
    #   age: {value:7, writable:false, enumerable:false}
    #   age: {get:(-> 7), enumerable:false}

    # Wrap the value if propInfo is not already a property definition
    if not propInfo?.get? and not propInfo?.value?
      propInfo = value: propInfo

    oj.addProperty obj, propName, propInfo

  return

# oj.addProperty
# ------------------------------------------------------------------------------
oj.addProperty = (obj, propName, propInfo) ->
  throw 'oj.addProperty: string expected for second argument' unless _.isString propName
  throw 'oj.addProperty: object expected for third argument' unless (_.isObject propInfo)
  throw 'oj.addProperty: get or value key expected in third argument' unless (propInfo.get? or propInfo.value?)

  _.defaults propInfo,
    enumerable: true
    configurable: true

  # Remove property if it already exists
  if obj[propName]?
    oj.removeProperty obj, propName

  # Add the property
  Object.defineProperty obj, propName, propInfo
  return

# oj.removeProperty
# ------------------------------------------------------------------------------

oj.removeProperty = (obj, propName) ->
  throw 'oj.addProperty: string expected for second argument' unless _.isString propName
  delete obj[propName]

# oj.isProperty
# ------------------------------------------------------------------------------
# Determine if the specified key is was defined by addProperty

oj.isProperty = (obj, propName) ->
  throw 'oj.isProperty: string expected for second argument' unless _.isString propName

  Object.getOwnPropertyDescriptor(obj, propName).get?

# oj.copyProperty
# ------------------------------------------------------------------------------
# Determine copy source.propName to dest.propName

oj.copyProperty = (dest, source, propName) ->
  info = Object.getOwnPropertyDescriptor source, propName
  Object.defineProperty dest, propName, info


# oj.partial (module, arg1, arg2, ...)
# ------------------------------------------------------------------------------
# Arguments are passed to exported module

oj.partial = (module, json) ->
  m = require module
  if (_.isFunction m) and arguments.length > 1
    return m arguments.slice(1)...
  m

# _.arguments
# ------------------------------------------------------------------------------
# Abstraction to wrap global arguments stack. This makes me sad but it is necessary for div -> syntax

# Stack of results
_.argumentsStack = []
# Result is top of the stack
oj.addProperty _, 'arguments', get: -> if _.argumentsStack.length then _.argumentsStack[_.argumentsStack.length-1] else null

# Push scope onto arguments
_.argumentsPush = (args = []) ->
  _.argumentsStack.push args
  return

# Pop scope from arguments
_.argumentsPop = ->
  if _.argumentsStack.length
    return _.argumentsStack.pop()
  null

# Append argument
_.argumentsAppend = (arg) ->
  if _.arguments
    _.arguments.push arg
  return

# oj.tag (name, attributes, content, content, ...)
# ------------------------------------------------------------------------------
#     name          String of the tag to serialize
#     attributes    (Optional) Object defining attributes of tag being serialized
#                   Keys have smart mappings:
#                       'c'  will map to 'class'
#                       'fontSize' will map to 'font-size'
#                       'borderRadius' will map to 'moz-border-radius', etc.


oj.tag = (name, args...) ->
  throw 'oj.tag error: argument 1 is not a string (expected tag name)' unless _.isString name

  # Build ojml starting with tag
  ojml = [name]

  # Get attributes from args by unioning all objects
  attributes = {}
  for arg in args
    # TODO: evaluate argument if necessary
    if _.isObject arg
      _.extend attributes, arg

  # Help the attributes out as they have shitting
  attributes = _tagAttributes name, attributes

  # Add attributes to ojml if they exist
  ojml.push attributes unless _.isEmpty attributes

  # Push arguments to build up children tags
  _.argumentsPush ojml

  # Loop over attributes
  for arg in args
    if _.isObject arg
      continue
    else if _.isFunction arg

      len = _.arguments.length

      # Call the argument it will auto append to _.arguments which is ojml
      r = arg()

      # Use return value if _.arguments weren't changed
      if len == _.arguments.length and r?
        _.argumentsAppend r

    else
      _.argumentsAppend arg

  # Pop to restore previous context
  _.argumentsPop()

  # Append the final result to your parent's arguments
  # if there exists an argument to append to
  _.argumentsAppend ojml

  ojml

oj.tag.elements =
  closed: 'a abbr acronym address applet article aside audio b bdo big blockquote body button canvas caption center cite code colgroup command datalist dd del details dfn dir div dl dt em embed fieldset figcaption figure font footer form frameset h1 h2 h3 h4 h5 h6 head header hgroup html i iframe ins keygen kbd label legend li map mark menu meter nav noframes noscript object ol optgroup option output p pre progress q rp rt ruby s samp script section select small source span strike strong style sub summary sup table tbody td textarea tfoot th thead time title tr tt u ul var video wbr xmp'.split ' '
  open: 'area base br col command embed hr img input keygen link meta param source track wbr'.split ' '

oj.tag.elements.all = (oj.tag.elements.closed.concat oj.tag.elements.open).sort()

oj.tag.isClosed = (tag) ->
  (_.indexOf oj.tag.elements.open, tag, true) == -1

# Create tag methods
for t in oj.tag.elements.all
  do (t) ->
    oj[t] = -> oj.tag t, arguments...

# Customize a few tags

_defaultClear = (dest, d, e) ->
  _.defaults dest, d
  for k of e
    dest[k] = null
  dest

_tagAttributes = (name, attributes) ->
  attr = _.clone attributes
  switch name
    when 'link' then _defaultClear attr, {rel:'stylesheet', type:'text/css', href: attr.url or attr.src}, {url:0, src:0}
    when 'script' then _defaultClear attr, {type:'text/javascript', src: attr.url}, url:0
    when 'a' then _defaultClear attr, {href:attr.url}, url:0
  attr

# oj.styles = ()

# oj.extend (context)
# ------------------------------------------------------------------------------
#     Extend oj methods into a context. Common contexts are `global` `window`
#     and `this` (used in coffee script). Helper methods are not extended (oj._)
#
#     context          Object to extend oj methods and objects into

oj.extend = (context) ->
  o = {}
  for k,v of oj
    if k[0] != '_'
      o[k] = v
  delete o.extend
  _.extend context, o

# oj.compile
# ------------------------------------------------------------------------------
# Return html and js after templating json

oj.compile = (options, ojml) ->

  # Options is optional
  if _.isArray options
    ojml = options
    options = {}

  options = _.defaults {}, options,
    html: true
    dom: false
    debug: false

  # TODO: When dom is implemented do not default html to always on
  # but for now it is required to generate the dom using innerHTML
  options.html = true

  options.html = if options.html then [] else null  # html accumulator
  options.dom = if options.dom then [] else null    # dom accumulator
  options.js = []                                   # code accumulator
  options.types = []                                # types accumulator
  options.indent = ''                               # indent counter

  _compileAny ojml, options

  # Join HTML only if the options ask for it
  html = options.html?.join ''

  # Generate DOM only if the options ask for it
  if document? and options.dom?
    el = document.createElement 'div'
    el.innerHTML = html
    options.dom = el.firstChild

  out = html: html, types: options.types, dom: options.dom, js:->
    # Call defered javascript
    for fn in options.js
      fn()
    # Call awaken for all objects
    for t in options.types
      t.awaken()
    undefined

  out

_styleKeyFromFancy = (key) ->
  out = ""
  # Loop over characters in key looking for camal case
  for c in key
    if _.isCapitalLetter c
      out += "-#{c.toLowerCase()}"
    else
      out += c
  out

# Convert object to string form
_styleFromObject = (obj) ->
  out = ""
  first = true
  for kFancy in _.keys(obj).sort()
    k = _styleKeyFromFancy kFancy
    if not first
      out += ';'
    out += "#{k}:#{obj[kFancy]}"
    first = false
  out

# Recursive helper for compiling that wraps indention
_compileDeeper = (method, ojml, options) ->
  i = options.indent
  options.indent += '\t'
  method ojml, options
  options.indent = i

# Compile ojml or any type
_compileAny = (ojml, options) ->

  switch oj.typeOf ojml

    when 'array'
      _compileTag ojml, options

    when 'oj'
      # Found an oj object. Compile its result
      _compileAny ojml.oj(), options

    when 'jquery'
      options.html?.push ojml[0].outerHTML

    when 'string'
      options.html?.push ojml

    when 'boolean', 'number'
      options.html?.push "#{ojml}"

    when 'function'
      _compileAny ojml(), options

    # Do nothing for 'null', 'undefined', 'object'

  return

# Supported events from jquery
events = bind:1, on:1, off:1, live:1, blur:1, change:1, click:1, dblclick:1, focus:1, focusin:1, focusout:1, hover:1, keydown:1, keypress:1, keyup:1, mousedown:1, mouseenter:1, mousemove:1, mouseout:1, mouseup:1, ready:1, resize:1, scroll:1, select:1

# Compile ojml tag (an array)
_compileTag = (ojml, options) ->

  # Get tag
  tag = ojml[0]

  # TODO: accept ojml with oj.Type instead of string for first element
  throw new Error('oj.compile: tag is missing in array') unless _.isString(tag) and tag.length > 0

  # Create oj object if tag is capitalized
  if _.isCapitalLetter tag[0]
    return _compileDeeper _compileAny, (new oj[tag] ojml.slice(1)), options

  # Get attributes (optional)
  attributes = null
  if _.isObject ojml[1]
    attributes = ojml[1]

  children = if attributes then ojml.slice 2 else ojml.slice 1

  # Compile to html if requested
  if options.html
    # attribute.style can be set with objects
    if _.isObject attributes?.style
      attributes.style = _styleFromObject attributes.style

    # attribute.c stands for class
    if attributes?.c?
      attributes.class = attributes.c
      attributes.c = null

    # attributes.class can be set with arrays
    if _.isArray attributes?.class
      attributes.class = attributes.join ' '

    # TODO: consider jsoning any object (good for attribute.data)

    # Convert attributes to string
    attr = ""
    if attributes

      # Filter out attributes that are events
      for k,v of attributes
        do(k,v) ->
          if events[k]?
            # Add attribute id if necessary
            attributes.id ?= oj.id()

            # Bind event if jquery exists
            if $?
              options.js?.push ->
                $el = $('#' + attributes.id)
                if _.isArray v
                  $el[k].apply @, v
                else
                  $el[k](v)
                return

            attributes[k] = null
          return

      # Serialize attributes in order for consistent output
      for k in _.keys(attributes).sort()
        if (v = attributes[k])?
          attr += " #{k}=\"#{v}\""

    # Start tag
    options.html?.push "<#{tag}#{attr}>"

  # Compile your children if necessary
  for child in children
    # Skip intention if there is only one child
    if options.debug && children.length > 1
      options.html?.push "\n\t#{options.indent}"
    _compileDeeper _compileAny, child, options

  # Skip intention if there is only one child
  if options.debug && children.length > 1
    options.html?.push "\n#{options.indent}"

  # End tag if you have children or your tag closes
  if children.length > 0 or oj.tag.isClosed(tag)
    options.html?.push "</#{tag}>"

# oj.toDOM
# ------------------------------------------------------------------------------
# Make oj directly in the DOM

oj.toDOM = (options, ojml) ->
  # Options is optional
  if not _.isObject options
    ojml = options
    options = {}

  # Create dom not html
  _.extend options,
    dom: true
    html: false

  result = oj.compile options, ojml

  # Bind js if it exists
  result.js?()

  result.dom

# oj.toHTML
# ------------------------------------------------------------------------------
# Make oj directly to HTML. It will ignore all event bindings

oj.toHTML = (options, ojml) ->
  # Options is optional
  if not _.isObject options
    ojml = options
    options = {}

  # Create html only
  _.extend options,
    dom: false
    html: true
    js: false

  (oj.compile options, ojml).html

# _.inherit
# ------------------------------------------------------------------------------
# Based on, but sadly, incompatable with coffeescript inheritance
_.inherit = (child, parent) ->

  # Copy class properties and methods
  for key of parent
    oj.copyProperty child, parent, key

  ctor = ->
  ctor:: = parent::
  child:: = new ctor()

  # Provide easy access for super methods
  # Example: @super.methodName(arguments...)
  child::super = parent::

  return

# oj.type
# ------------------------------------------------------------------------------

oj.type = (name, args = {}) ->

  throw 'oj.type: string expected for first argument' unless _.isString name
  throw 'oj.type: object expected for second argument' unless _.isObject args

  args.methods ?= {}
  args.properties ?= {}
  args.constructor ?= ->

  Out = new Function("""return function #{name}(){
    var _this = this;
    if ( !(this instanceof #{name}) )
      _this = new #{name};

    #{name}.prototype.constructor.apply(_this, arguments);

    return _this;
  }
  """
  )();

  # Alias 'extends' to 'inherits' for javascript folks
  args.extends ?= args.inherits

  # Inherit if necessary
  if args.extends?
    _.inherit Out, args.extends

  # Add the constructor and wrap it to automatically call super.constructor
  oj.addMethod Out::, 'constructor', ->

    # Call your super's constructor
    if args.extends?
      (args.extends)::constructor.apply @, arguments

    # Then call your own constructor
    try
      args.constructor.apply @, arguments
    catch e
      console.error "#{name}.constructor failed with: ", e
      throw e
    return @

  # Mark new type and its instances with a non-enumerable _type and _oj properties
  typeProps =
    type: {value:name, writable:false, enumerable:false}
    isOJ: {value:true, writable:false, enumerable:false}
  oj.addProperties Out, typeProps
  oj.addProperties Out::, typeProps

  # Add properties helper to instance and type
  propKeys = (_.keys args.properties).sort()
  if Out::properties?
    propKeys = _.uniqueSortedUnion Out::properties, propKeys
  properties = value:propKeys, writable:false, enumerable:false
  oj.addProperty Out, 'properties', properties
  oj.addProperty Out::, 'properties', properties

  # Add methods helper to instance and type
  methodKeys = (_.keys args.methods).sort()
  if Out::methods?
    methodKeys = _.uniqueSortedUnion Out::methods, methodKeys
  methods = value:methodKeys, writable:false, enumerable:false
  oj.addProperty Out, 'methods', methods
  oj.addProperty Out::, 'methods', methods

  # Add methods to the type
  _.extend args.methods,

    # set: Set all properties on the object at once
    set: (k,v) ->
      obj = k
      if not _.isObject k
        obj = {}
        obj[k] = v;
      for key,value of obj
        @[key] = value
      return

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

# oj.view
# ------------------------------------------------------------------------------

oj.view = (name, args) ->
  throw 'oj.view: string expected for first argument' unless _.isString name
  throw 'oj.view: object expected for second argument' unless _.isObject args
  args.extends ?= oj.View
  oj.type name, args

# oj.View
# ------------------------------------------------------------------------------
# Properties
#   $el           Reference el
#   attributes    Initialize from element, $(selector), or ojml

# Methods
#   css

oj.View = oj.type 'View',
  constructor: ->

    # TODO: Process arguments if they are functions and wrap _.arguments

    @make.apply @, arguments

    # Views act like tag methods and support the div -> syntax.
    # Append this to parent
    _.argumentsAppend @

  properties:
    el:
      get: ->
        if @_el
          @_el
        else
          ojml = @make()
          result = oj.compile(dom:true, ojml).dom
          @_el = result
      set: (v) -> @_el = v
    $el:
      get: -> $(@el)
    id:
      get: -> @$el.attr 'id'
      set: (v) -> @$el.attr 'id', v

    hidden:
      get: -> $el.css('display') == 'none'
      set: (v) -> if v then $el.hide() else $el.show()
    css:
      get: -> throw 'css getter nyi'
      set: -> throw 'css setter nyi'

    style:
      get: -> throw 'style getter nyi'
      set: -> throw 'style setter nyi'

  methods:
    # make: Return ojml that creates initial dom state
    # should be overriden by subclass if it isn't
    make: -> oj.div c:"oj.#{oj.typeOf @}", id:oj.id()

    # Find sub elements via jquery selector
    $: -> @$el.find(arguments...)
    hide: -> @$el.hide()
    show: -> @$el.show()
    toString: -> @el.outerHTML

    # Detach element from dom but remember where it went
    detach: -> throw 'detach nyi'

    # Attach element to dom where it use to be
    attach: -> throw 'attach nyi'

# oj.Checkbox
# ------------------------------------------------------------------------------
# Checkbox control

oj.Checkbox = oj.type 'Checkbox'
  extends: oj.View
  constructor: ->
    @set arguments...

  properties:

    value:
      get: -> @_value
      set: (v) -> @_value = v; return

    disabled:
      get: -> @el.disabled
      set: (v) -> @el.disabled = v; return

  methods:
    make: ->
      oj.input id: oj.id(), c:@type, type:'checkbox'#, checked:checked

    toString: ->
      @super.toString.apply @,arguments

# oj.List
# ------------------------------------------------------------------------------
# List control

# oj.List = oj.type 'List',
#   constructor: ->

#   methods:

# oj.Link
# ------------------------------------------------------------------------------
# oj.Link = class Link extends Control

# oj.domReplace
# ------------------------------------------------------------------------------
# Replace element's html with jsml.  Starts OJ objects.
oj.replace = (el, ojml) ->
  # Element can be dom or jquery
  el = el.get(0) if _.isjQuery el
  # Template
  template = oj.template ojml
  # Replace
  _.domReplaceHtml el, template.html
  # initialize
  template.js()

# domInsertElementAfter
# ------------------------------------------------------------------------------
# DOM utility function to help insert elements after a given element (similar to domInsertBefore)

_.domInsertElementAfter = (elLocation, elToInsert) ->
  throw new Error("domInsertElementAfter error: elementLocation is null") unless elLocation
  throw new Error("domInsertElementAfter error: elementToInsert is null") unless elToInsert
  elNext = elLocation.nextSibling
  elParent = elLocation.parentNode
  if elNext
    elParent.insertBefore elToInsert, elNext
  else
    elParent.appendChild elToInsert

# domReplaceHtml
# ------------------------------------------------------------------------------
#
# Source: http://www.bigdumbdev.com/2007/09/replacehtml-remove-insert-put-back-is.html
#
# Basic idea is that setting html on something not on the dom is faster
# TODO: Allow insertion of TR into TBODY.  Must recognize parent tag of destination and make the temporary tag match this.  With TBODY you then need to add TABLE as well.

_.domReplaceHtml = (el, html) ->
  throw new Error("domReplaceHtml error: element is null") unless el
  nextSibling = el.nextSibling
  parent = el.parentNode
  parent.removeChild el
  el.innerHTML = html
  if nextSibling
    parent.insertBefore el, nextSibling
  else
    parent.appendChild el

# domAppendHtml
# ------------------------------------------------------------------------------
# Append html after all children of element

# TODO: Allow insertion of TR into TBODY.
_.domAppendHtml = (el, html) ->
  throw new Error("oj.domAppendHtml: element is null") unless el
  elTemp = document.createElement 'div'
  elTemp.innerHTML = html
  while elTemp.childNodes.length
    el.appendChild elTemp.childNodes[0]
  elTemp = undefined

# domPrependHtml
# ------------------------------------------------------------------------------
# Prepend html before all children of element
# TODO: Allow insertion of TR into TBODY.

_.domPrependHtml = (el, html) ->
  throw new Error("oj.domPrependHtml: element is null") unless el
  elTemp = document.createElement 'div'
  elTemp.innerHTML = html
  while elTemp.childNodes.length
    el.insertBefore elTemp.childNodes[elTemp.childNodes.length-1], el.childNodes[0]
  elTemp = undefined

# domInsertHtmlBefore
# ------------------------------------------------------------------------------
# Insert html before the given element
# TODO: Allow insertion of TR into TBODY.

_.domInsertHtmlBefore = (el, html) ->
  throw new Error("oj.domInsertHtmlBefore: element is null") unless el
  # special case
  elTemp = document.createElement 'div'
  elTemp.innerHTML = html
  parent = el.parentNode
  while elTemp.childNodes.length
    parent.insertBefore elTemp.childNodes[elTemp.childNodes.length-1], el
  elTemp = undefined

# domInsertHtmlAfter
# ------------------------------------------------------------------------------
# Insert html after the given element
# TODO: Allow insertion of TR into TBODY.

_.domInsertHtmlAfter = (el, html) ->
  throw new Error("oj.domInsertHtmlAfter: element is null") unless el
  elTemp = document.createElement 'div'
  elTemp.innerHTML = html
  elBefore = el
  while elTemp.childNodes.length
    elBeforeNext = elTemp.childNodes[0]
    _.domInsertElementAfter elBefore, elTemp.childNodes[0]
    elBefore = elBeforeNext

  elTemp = undefined



oj.insertAfter
oj.insertBefore
oj.replace





