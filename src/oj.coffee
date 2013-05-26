
# oj
# ==============================================================================
# A unified templating framework for the people. Thirsty people.

# oj function
# ------------------------------------------------------------------------------
# Convert ojml to dom
oj = module.exports = ->
  # Prevent oj method from propagating
  _.argumentsPush()
  ojml = oj.emit.apply @, arguments
  _.argumentsPop()
  ojml

# Emit arguments as if it was an oj tag function
oj.emit = ->
  ojml = oj.tag 'oj', arguments...

# Keep a reference to ourselves for templates to see
oj.oj = oj

# oj.begin
# ------------------------------------------------------------------------------

oj.begin = (page) ->

  # Defer dom manipulation until the page has loaded
  _readyOrLoad ->

    # Compile only the body and below
    bodyOnly = html:1, doctype:1, head:1, link:1, script:1
    {dom,types} = oj.compile dom:1, html:0, css:0, ignore:bodyOnly, (require page)

    if not dom?
      console.error 'oj: dom failed to compile'
      return

    # Find body
    body = document.getElementsByTagName('body')
    if body.length == 0
      console.error 'oj: <body> was not found'
      return
    body = body[0]

    # Clear body and insert dom elements
    body.innerHTML = ''
    if not oj.isArray dom
      dom = [dom]
    for d in dom
      body.appendChild d

    for t in types
      t.inserted()

    # Trigger events bound through oj.ready
    oj.ready()

# Helpers
# ------------------------------------------------------------------------------
# Loading with either ready or onload (whichever exists)
# Loads immediately if it is already loaded
_readyOrLoad = (fn) ->
  # Use jquery ready if it exists
  if $?
    $(fn)
  # Otherwise fall back to onload
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

# oj.ready
# -----------------------------------------------------------------------------
_readyQueue = queue:[], loaded:false
oj.ready = (f) ->
  # Call everything if no arguments
  if oj.isUndefined f
    _readyQueue.loaded = true
    while (f = _readyQueue.queue.shift())
      f()
  # Call load if already loaded
  else if _readyQueue.loaded
    f()
  # Queue function for later
  else
    _readyQueue.queue.push f
  return

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

  stripBOM = (c) -> if c.charCodeAt(0) == 0xFEFF then (c.slice 1) else c

  wrapJS = (code) ->
    "(function(){with(oj.sandbox){#{code}}}).call(this);"

  wrapCSMessage = (message, filepath) ->
    "#{oj.codes?.red}coffee-script error in #{filepath}: #{message}#{oj.codes?.reset}"
  wrapJSMessage = (message, filepath) ->
    "#{oj.codes?.red}javascript error in #{filepath}: #{message}#{oj.codes?.reset}"

  compileJS = (module, code, filepath) ->
    code = wrapJS code
    global.oj = oj
    module._compile code, filepath
    delete global.oj

  # .oj files are compiled as javascript
  require.extensions['.oj'] = (module, filepath) ->
    code = stripBOM fs.readFileSync filepath, 'utf8'
    try
      compileJS module, code, filepath
    catch eJS
      eJS.message = wrapJSMessage eJS.message, filepath
      throw eJS

  # .ojc files are compiled as coffee-script
  require.extensions['.ojc'] = (module, filepath) ->
    code = stripBOM fs.readFileSync filepath, 'utf8'

    # Compile in coffee-script
    try
      code = coffee.compile code, bare: true
    catch eCoffee
      eCoffee.message = wrapCSMessage eCoffee.message, filepath
      throw eCoffee

    # Compile javascript
    try
      compileJS module, code, filepath

    catch eJS
      eJS.message = wrapJSMessage eJS.message, filepath
      throw eJS

  # TODO: .ojlc files are compiled as literate coffee-script

root = @

oj.version = '0.0.14'

oj.isClient = not process?.versions?.node

# Export for NodeJS if necessary
if typeof module != 'undefined'
  exports = module.exports = oj
else
  root['oj'] = oj

# Type Helpers
# ------------------------------------------------------------------------------
# Based on [underscore.js](http://underscorejs.org/)
# The potential duplication saddens me but oj needs sophisticated type detection

ArrayP = Array.prototype
FuncP = Function.prototype
ObjP = Object.prototype

slice = ArrayP.slice
unshift = ArrayP.unshift
concat = ArrayP.concat

oj.isUndefined = (obj) -> obj == undefined
oj.isBoolean = (obj) -> obj == true or obj == false or ObjP.toString.call(obj) == '[object Boolean]'
oj.isNumber = (obj) -> !!(obj == 0 or (obj and obj.toExponential and obj.toFixed))
oj.isString = (obj) -> !!(obj == '' or (obj and obj.charCodeAt and obj.substr))
oj.isDate = (obj) -> !!(obj and obj.getTimezoneOffset and obj.setUTCFullYear)
oj.isFunction = (obj) -> typeof obj == 'function'
oj.isArray = Array.isArray or (obj) -> ObjP.toString.call(obj) == '[object Array]'
oj.isRegEx = (obj) -> ObjP.toString.call(obj) == '[object RegExp]'
oj.isDOM = (obj) -> !!(obj and obj.nodeType?)
oj.isDOMElement = (obj) -> !!(obj and obj.nodeType == 1)
oj.isDOMAttribute = (obj) -> !!(obj and obj.nodeType == 2)
oj.isDOMText = (obj) -> !!(obj and obj.nodeType == 3)
oj.isjQuery = (obj) -> !!(obj and obj.jquery)
oj.isEvented = (obj) -> !!(obj and obj.on and obj.off and obj.trigger)
oj.isOJ = (obj) -> !!(obj?.isOJ)
oj.isArguments = (obj) -> ObjP.toString.call(obj) == '[object Arguments]'
oj.isDefined = (obj) -> not (typeof obj == 'undefined')

# typeOf: Mimic behavior of built-in typeof operator and integrate jQuery, Backbone, and OJ types
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

# Determine if obj is a vanilla object
oj.isObject = (obj) -> (oj.typeOf obj) == 'object'

# Utility: Helpers
# ------------------------------------------------------------------------------
# Some are from [underscore.js](http://underscorejs.org/).

oj.__ = _ = {}
_.isCapitalLetter = (c) -> !!(c.match /[A-Z]/)
_.identity = (v) -> v
_.property = (obj, options = {}) ->
  # _.defaults options, configurable: false
  Object.defineProperty obj, options
_.has = (obj, key) -> ObjP.hasOwnProperty.call(obj, key)
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
    if oj.isArray value
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
    throw new TypeError unless oj.isFunction(func)
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

_.toArray = (obj) ->
  return [] if !obj
  return slice.call obj if oj.isArray obj
  return slice.call obj if oj.isArguments obj
  return obj.toArray() if obj.toArray and oj.isFunction(obj.toArray)
  _.values obj

# Determine if object or array is empty
_.isEmpty = (obj) ->
  return obj.length == 0 if oj.isArray obj
  for k of obj
    if _.has obj, k
      return false
  true

_.clone = (obj) ->
  # TODO: support cloning OJ instances
  # TODO: support options, deep: true
  return obj unless oj.isObject obj
  if oj.isArray obj then obj.slice() else _.extend {}, obj

_.contains = (obj, target) ->
  if not obj?
    return false
  if ArrayP.indexOf and obj.indexOf == ArrayP.indexOf
    return obj.indexOf(target) != -1
  _.any obj, (value) -> value == target

_.some = _.any = (obj, iterator, context) ->
    iterator ?= _.identity
    result = false
    if not obj?
      return result
    if ArrayP.some and obj.some == ArrayP.some
      return obj.some iterator, context
    _.each obj, (value, index, list) ->
      if result or (result = iterator.call(context, value, index, list))
        return breaker
    return !!result

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
  else if oj.isArray col
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
    _.each(obj, ((v, ix, list) ->
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

_.omit = (obj) ->
  copy = {}
  keys = concat.apply ArrayP, slice.call(arguments, 1)
  for key of obj
    if not _.contains keys, key
      copy[key] = obj[key]
  copy

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

_.debounce = (wait, func, immediate) ->
  timeout = null
  result = null
  ->
    context = @
    args = arguments
    later = ->
      timeout = null;
      if !immediate
        result = func.apply context, args

    callNow = immediate and !timeout
    clearTimeout timeout
    timeout = setTimeout later, wait
    if callNow
      result = func.apply context, args
    result

# Path Helpers
# ------------------------------------------------------------------------------
# Based on node.js/path module
# All we need is join,resolve,dirname

pathNormalizeArray = (parts, allowAboveRoot) ->
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

pathSplitRe = /^(\/?)([\s\S]+\/(?!$)|\/)?((?:\.{1,2}$|[\s\S]+?)?(\.[^.\/]*)?)$/
pathSplit = (filename) ->
  result = pathSplitRe.exec filename
  [result[1] or '', result[2] or '', result[3] or '', result[4] or '']

_.pathResolve = ->
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
  resolvedPath = pathNormalizeArray(resolvedPath.split('/').filter((p) ->
    return !!p
  ), !resolvedAbsolute).join('/')

  ((if resolvedAbsolute then '/' else '') + resolvedPath) or '.'

_.pathNormalize = (path) ->
  isAbsolute = path.charAt(0) == '/'
  trailingSlash = path.substr(-1) == '/'

  # Normalize the path
  path = pathNormalizeArray(path.split('/').filter((p) ->
    !!p
  ), !isAbsolute).join('/')

  if !path and !isAbsolute
    path = '.'

  if path and trailingSlash
    path += '/'

  (if isAbsolute then '/' else '') + path

_.pathJoin = ->
  paths = Array.prototype.slice.call arguments, 0
  _.pathNormalize(paths.filter((p, index) ->
    p and typeof p == 'string'
  ).join('/'))

_.pathDirname = (path) ->
  result = pathSplit path
  root = result[0]
  dir = result[1]
  if !root and !dir
    # No dirname whatsoever
    return '.'
  if dir
    # It has a dirname, strip trailing slash
    dir = dir.substr 0, dir.length - 1
  root + dir

# oj.dependency
# ------------------------------------------------------------------------------
# Ensure dependencies through oj plugins

oj.dependency = (name) ->
  obj = if oj.isClient then window[name] else global[name]
  throw new Error("oj: #{name} dependency is missing") unless oj.isDefined obj

# Depend on jQuery
oj.dependency 'jQuery'

# oj.addMethod
# ------------------------------------------------------------------------------
oj.addMethods = (obj, mapNameToMethod) ->
  for methodName, method of mapNameToMethod
    oj.addMethod obj, methodName, method
  return

# oj.addMethod
# ------------------------------------------------------------------------------
oj.addMethod = (obj, methodName, method) ->
  throw 'oj.addMethod: string expected for second argument' unless oj.isString methodName
  throw 'oj.addMethod: function expected for thrid argument' unless oj.isFunction method
  Object.defineProperty obj, methodName,
    value: method
    enumerable: false
    writable: false
    configurable: true
  return

# oj.removeMethod
# ------------------------------------------------------------------------------
oj.removeMethod = (obj, methodName) ->
  throw 'oj.removeMethod: string expected for second argument' unless oj.isString methodName
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
      propInfo = value: propInfo, writable:true

    oj.addProperty obj, propName, propInfo

  return

# oj.addProperty
# ------------------------------------------------------------------------------
oj.addProperty = (obj, propName, propInfo) ->
  throw 'oj.addProperty: string expected for second argument' unless oj.isString propName
  throw 'oj.addProperty: object expected for third argument' unless (oj.isObject propInfo)

  _.defaults propInfo,
    enumerable: true
    configurable: true

  # Remove property if it already exists
  if Object.getOwnPropertyDescriptor(obj, propName)?
    oj.removeProperty obj, propName

  # Add the property
  Object.defineProperty obj, propName, propInfo
  return

# oj.removeProperty
# ------------------------------------------------------------------------------

oj.removeProperty = (obj, propName) ->
  throw 'oj.addProperty: string expected for second argument' unless oj.isString propName
  delete obj[propName]

# oj.isProperty
# ------------------------------------------------------------------------------
# Determine if the specified key is was defined by addProperty

oj.isProperty = (obj, propName) ->
  throw 'oj.isProperty: string expected for second argument' unless oj.isString propName

  Object.getOwnPropertyDescriptor(obj, propName).get?

# oj.copyProperty
# ------------------------------------------------------------------------------
# Determine copy source.propName to dest.propName

oj.copyProperty = (dest, source, propName) ->
  info = Object.getOwnPropertyDescriptor source, propName
  Object.defineProperty dest, propName, info

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

  throw 'oj.tag error: argument 1 is not a string (expected tag name)' unless oj.isString name

  # Build ojml starting with tag
  ojml = [name]

  # Get attributes from args by unioning all objects
  attributes = {}
  for arg in args
    # TODO: evaluate argument if necessary
    if oj.isObject arg
      _.extend attributes, arg

  # Help the attributes out as they have shitting
  attributes = _tagAttributes name, attributes

  # Add attributes to ojml if they exist
  ojml.push attributes unless _.isEmpty attributes

  # Push arguments to build up children tags
  _.argumentsPush ojml

  # Loop over attributes
  for arg in args
    if oj.isObject arg
      continue
    else if oj.isFunction arg

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
  open: 'area base br col command css !DOCTYPE embed hr img input keygen link meta param source track wbr'.split ' '

oj.tag.elements.all = (oj.tag.elements.closed.concat oj.tag.elements.open).sort()

oj.tag.isClosed = (tag) ->
  (_.indexOf oj.tag.elements.open, tag, true) == -1

# Helper to set tag name on a tag
_setTagName = (tag, name) ->
  if tag?
    tag.tagName = name
  return

# Helper to get tag name on a tag
_getTagName = (tag) ->
  tag.tagName

# Helper to get instance on element
_getInstanceOnElement = (el) ->
  if el?.oj?
    el.oj
  else
    null

# Helper to set instance on element
_setInstanceOnElement = (el, inst) ->
  el?.oj = inst
  return

# Create tag methods
for t in oj.tag.elements.all
  do (t) ->
    oj[t] = -> oj.tag t, arguments...
    # Remember the tag name
    _setTagName oj[t], t

# Clear attributes
_defaultClear = (dest, d, e) ->
  _.defaults dest, d
  for k of e
    delete dest[k]
  dest

# Adjust tag attributes
_tagAttributes = (name, attributes) ->
  attr = _.clone attributes
  switch name

    # link tags default to stylesheet, text/css, url instead of href
    when 'link' then _defaultClear attr, {rel:'stylesheet', type:'text/css', href: attr.url or attr.src}, {url:0, src:0}

    # script tags default to javascript, url instead of src
    when 'script' then _defaultClear attr, {type:'text/javascript', src: attr.url}, url:0

    # anchor tags can use url instead of href
    when 'a' then _defaultClear attr, {href:attr.url}, url:0
  attr


# doctype tag
# ------------------------------------------------------------------------------

dhp = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01'
w3 = '"http://www.w3.org/TR/html4/'
strict5 = '<!DOCTYPE html>'
strict4 = dhp+'//EN" '+w3+'strict.dtd">'

doctypes =
  '5': strict5
  'HTML 5': strict5
  '4': strict4
  'HTML 4.01 Strict': strict4
  'HTML 4.01 Frameset': dhp+' Frameset//EN" '+w3+'frameset.dtd">'
  'HTML 4.01 Transitional': dhp+' Transitional//EN" '+w3+'loose.dtd">'

oj.doctype = (type = 5) ->
  # Emit like a tag
  ojml = doctypes[type]
  _.argumentsAppend ojml
  ojml

# oj.page
# ------------------------------------------------------------------------------
# General template for oj to not need html, head, body tags

oj.page = (options, content) ->
  # Options is optional
  if not content?
    content = options
    options = {}

  oj.html ->
    oj.head ->
      if options.title?
        oj.title options.title
    oj.body ->
      content()

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
# Compile ojml into meaningful parts
# options
#     html:true           Compile to html
#     dom:true            Compile to dom
#     css:true            Compile to css
#     debug:true          Keep all source including comments
#     ignore:{html:1}     Map of tags to ignore while compiling

oj.compile = (options, ojml) ->

  # Options is optional
  if not ojml?
    ojml = options
    options = {}

  # Default options to compile everything
  options = _.defaults {}, options,
    html: true
    dom: true
    css: true
    cssMap: false
    debug: false
    ignore: {}

  # Always ignore oj and css tags
  _.extend options.ignore, oj:1, css:1

  acc = _.clone options
  acc.html = if options.html then [] else null    # html accumulator
  acc.dom = if options.dom and document? then (document.createElement 'OJ') else null
  acc.css = if options.css || options.cssMap then {} else null
  acc.indent = ''                                 # indent counter
  acc.types = [] if options.dom                   # remember types if making dom
  acc.tags = {}                                   # remember what tags were used
  _compileAny ojml, acc

  # Generate cssMap
  if options.cssMap
    cssMap = acc.css

  # Generate css
  if options.css
    css = _cssFromObject acc.css, options.debug

  # Generate HTML
  if options.html
    html = acc.html.join ''

  # Generate dom
  if options.dom

    # Remove the <oj> wrapping from the dom element
    dom = acc.dom.childNodes

    # Cleanup inconsistencies of childNodes
    if dom.length?
      # Make dom a real array
      dom = _.toArray dom
      # Filter out anything that isn't a dom element
      dom = dom.filter (v) -> oj.isDOM(v)

    # Ensure dom is null if empty
    if dom.length == 0
      dom = null

    # Single elements are returned themselves not as a list
    # Reasoning: The common cases don't have multiple elements <html>,<body>
    # or the complexity doesn't matter because insertion is abstracted for you
    # In short it is easier to check for _.isArray dom, then _isArray dom && dom.length > 0
    else if dom.length == 1
      dom = dom[0]

  out = html:html, dom:dom, css:css, cssMap:cssMap, types:acc.types, tags:acc.tags

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

# _styleFromObject: Convert object to string form
# -----------------------------------------------------------------------------
#
#     inline:false      inline:true                inline:false,indent:true
#     color:red;        color:red;font-size:10px   \tcolor:red;
#     font-size:10px;                              \tfont-size:10px;
#

_styleFromObject = (obj, options = {}) ->
  _.defaults options,
    inline: true
    indent: false
  # Trailing semi should only exist on when we aren't indenting
  options.semi = !options.inline
  out = ""
  keys = _.keys(obj).sort()
  indent = if options.indent then '\t' else ''
  newline = if options.inline then '' else '\n'
  for kFancy,ix in keys
    # Add semi if it is not inline or it is not the last key
    semi = if options.semi or ix != keys.length-1 then ";" else ''
    k = _styleKeyFromFancy kFancy
    out += "#{indent}#{k}:#{obj[kFancy]}#{semi}#{newline}"
  out

# _attributesFromObject: Convert object to attribute string
# -----------------------------------------------------------------------------
# This object has nothing special. No renamed keys, no jquery events. It is
# precicely what must be serialized with no adjustment.
_attributesFromObject = (obj) ->
  # Pass through non objects
  return obj if not oj.isObject obj

  out = ''
  # Serialize attributes in order for consistent output
  space = ''
  for k in _.keys(obj).sort()
    v = obj[k]

    # Boolean attributes have no value
    if (v == true)
      out += "#{space}#{k}"

    # Other attributes have a value
    else
      out += "#{space}#{k}=\"#{v}\""

    space = ' '
  out

# _cssFromObject:
# -----------------------------------------------------------------------------
# Convert css selectors and rules to a string
#
#     debug:true               debug:false
#     .cls {                   .cls{color: red}
#         color: red;
#     }\n

_cssFromObject = (cssMap, isDebug = 0) ->
  newline = if isDebug then '\n' else ''
  space = if isDebug then ' ' else ''
  inline = !isDebug
  indent = isDebug
  css = ''
  for selector, styles of cssMap
    rules = _styleFromObject styles, inline:inline, indent:indent
    css += "#{selector}#{space}{#{newline}#{rules}}#{newline}"
  css

# Recursive helper for compiling that wraps indention
_compileDeeper = (method, ojml, options) ->
  i = options.indent
  options.indent += '\t'
  method ojml, options
  options.indent = i

# Compile ojml or any type
pass = ->
_compileAny = (ojml, options) ->

  switch oj.typeOf ojml

    when 'array'
      _compileTag ojml, options

    when 'jquery'
      # TODO: Missing unit tests for the jquery case
      options.html?.push ojml.html()
      options.dom?.concat ojml.get()

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
        options.html?.push ojml.toHTML()
        options.dom?.appendChild ojml.toDOM()
        if options.css?
          _.extend options.css, ojml.toCSSMap()

  return

# Supported events from jquery
jqueryEvents = bind:1, on:1, off:1, live:1, blur:1, change:1, click:1, dblclick:1, focus:1, focusin:1, focusout:1, hover:1, keydown:1, keypress:1, keyup:1, mousedown:1, mouseenter:1, mousemove:1, mouseout:1, mouseup:1, ready:1, resize:1, scroll:1, select:1

# Compile ojml tag (an array)
_compileTag = (ojml, options) ->

  # Empty list compiles to nothing
  return if ojml.length == 0

  # Get tag
  tag = ojml[0]
  tagType = typeof tag

  # Allow ojml's tag parameter to be 'table' or table or Table
  tag = if (tagType == 'function' or tagType == 'object') and _getTagName(tag)? then _getTagName(tag) else tag

  # Fail if we couldn't find a string by now
  throw new Error('oj.compile: tag name is missing') unless oj.isString(tag) and tag.length > 0

  # Create oj object if tag is capitalized
  if _.isCapitalLetter tag[0]
    return _compileDeeper _compileAny, (new oj[tag] ojml.slice(1)), options

  # Record tag
  options.tags[tag] = true

  # Get attributes (optional)
  attributes = null
  if oj.isObject ojml[1]
    attributes = ojml[1]

  # Remaining arguments are children of this tag
  children = if attributes then ojml.slice 2 else ojml.slice 1

  # Compile to css if requested
  if options.css and tag == 'css'

    # Extend options.css with rules
    for selector,styles of attributes
      options.css[selector] ?= styles
      _.extend options.css[selector], styles

  # Compile to html if requested
  if not options.ignore[tag]

    events = _attributesProcessedForOJ attributes

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
        for attrName in _.keys(attributes).sort()
          attrValue = attributes[attrName]
          # Boolean attributes have no value
          if attrValue == true
            att = document.createAttribute attrName
            el.setAttributeNode att
          else
            el.setAttribute attrName, attrValue

      # Bind events
      _attributesBindEventsToDOM events, el

    # Add tag with attributes
    if options.html
      attr = (_attributesFromObject attributes) ? ''
      space = if attr == '' then '' else ' '
      options.html.push "<#{tag}#{space}#{attr}>"


  # Compile your children if necessary
  for child in children
    # Skip intention if there is only one child
    if options.debug && children.length > 1
      options.html?.push "\n\t#{options.indent}"
    _compileDeeper _compileAny, child, options

  # Skip intention if there is only one child
  if options.debug && children.length > 1
    options.html?.push "\n#{options.indent}"

  # End html tag if you have children or your tag closes
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

# Allow attributes to alias c to class
_attributeCMeansClass = (attr) ->
  if attr?.c?
    attr.class = attr.c
    delete attr.c
  return

# Allow attributes to take class as an array of strings
_attributeClassAllowsArrays = (attr) ->
  if oj.isArray attr?.class
    attr.class = attr.join ' '
  return

# Omit falsy values except for zero
_attributeOmitFalsyValues = (attr) ->
  if oj.isObject attr
    # Filter out falsy except for 0
    for k,v of attr
      delete attr[k] if v == null or v == undefined or v == false

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
  _attributeCMeansClass attr

  # style takes objects
  _attributeStyleAllowsObject attr

  # class takes arrays
  _attributeClassAllowsArrays attr

  # Omit keys that false, null, or undefined
  _attributeOmitFalsyValues attr

  # TODO: Consider jsoning anything that isn't a string
  # any keys that aren't strings are jsoned
  # _attributesJSONAllKeys attributes

  # Filter out jquery events
  events = _attributesFilterOutEvents attr

  # Returns bindable events
  events

# Bind events to dom
_attributesBindEventsToDOM = (events, el) ->
  for ek, ev of events
    if $?
      if oj.isArray ev
        $(el)[ek].apply @, ev
      else
        $(el)[ek](ev)
    else
      console.error "oj: jquery is missing when binding a '#{ek}' event"

# oj.toHTML
# ------------------------------------------------------------------------------
# Make oj directly to HTML. It will ignore all event bindings

oj.toHTML = (options, ojml) ->
  # Options is optional
  if not oj.isObject options
    ojml = options
    options = {}

  # Create html only
  _.extend options,
    dom: false
    js: false
    html: true
    css: false

  (oj.compile options, ojml).html

# oj.toCSS
# ------------------------------------------------------------------------------
# Make oj directly to css. It will ignore all event bindings and html

oj.toCSS = (options, ojml) ->
  # Options is optional
  if not oj.isObject options
    ojml = options
    options = {}

  # Create html only
  _.extend options,
    dom: false
    js: false
    html: false
    css: true

  (oj.compile options, ojml).css

# _.inherit
# ------------------------------------------------------------------------------
# Based on, but sadly incompatable with, coffeescript inheritance
_.inherit = (child, parent) ->

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

# oj.type
# ------------------------------------------------------------------------------

oj.type = (name, args = {}) ->
  throw 'oj.type: string expected for first argument' unless oj.isString name
  throw 'oj.type: object expected for second argument' unless oj.isObject args

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
    _.inherit Out, args.base

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
  propKeys = (_.keys args.properties).sort()
  if Out::properties?
    propKeys = _.uniqueSortedUnion Out::properties, propKeys
  properties = value:propKeys, writable:false, enumerable:false
  # propKeys.has = _.reduce propKeys, ((o,item) -> o[item.key] = true; o), {}
  oj.addProperty Out::, 'properties', properties

  # Add methods helper to instance
  methodKeys = (_.keys args.methods).sort()
  if Out::methods?
    methodKeys = _.uniqueSortedUnion Out::methods, methodKeys
  methods = value:methodKeys, writable:false, enumerable:false
  # methodKeys.has = _.reduce methodKeys, ((o,item) -> o[item.key] = true; o), {}
  oj.addProperty Out::, 'methods', methods

  # Add methods to the type
  _.extend args.methods,

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
    # TODO: Make this O(1)
    has: (k) ->
      _.some @properties, (v) -> v == k

    # can: Determine if method exists
    # TODO: Make this O(1)
    can: (k) ->
      _.some @methods, (v) -> v == k

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

# argumentsUnion:
# Take arguments and tranform them into options and args.
# options is a union of all items in `arguments` that are objects
# args is a concat of all arguments that aren't objects in the same order
oj.argumentsUnion = (argList) ->
  obj = {}
  list = []
  for v in argList
    if oj.isObject v
      obj = _.extend obj, v
    else
      list.push v
  options: obj, args: list

# oj.enum
# ------------------------------------------------------------------------
oj.enum = (name, args) ->
  throw 'NYI'

# oj.View
# ------------------------------------------------------------------------------

oj.View = oj.type 'View',

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
    options = _.omit options, @properties...

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
          {dom:@_el, cssMap:@cssMap} = oj.compile css:0, cssMap:1, dom:1, html:0, v
        return

    # Get and cache jquery-enabled element (readonly)
    $el: get: -> @_$el ? (@_$el = $ @el)

    # Get all attributes (readonly)
    attributes: get: ->
      out = {}
      $.each @el.attributes, (index, attr) -> out[ attr.name ] = attr.value;
      out

    # Get and set id of view from attribute
    id:
      get: -> @$el.attr 'id'
      set: (v) -> @$el.attr 'id', v

    # CSS generated for this instance
    cssMap:
      get: -> @_cssMap ? {}
      set: (v) ->
        @_cssMap = v

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

    # Add attributes and apply the oj magic with jquery binding
    addAttributes: (attributes) ->
      attr = _.clone attributes

      events = _attributesProcessedForOJ attr

      # Add attributes as object
      if oj.isObject attr
        for k,v of attr

          # Wrap k in quotes if it has whitespace
          if k == 'class'
            @$el.addClass v

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

    # emit: Emit instance as a tag function would do
    emit: -> _.argumentsAppend @; return

    # Convert View to html
    toHTML: (options) ->
      @el.outerHTML + (if options?.debug then '\n' else '')

    # Convert View to dom (for compiling)
    toDOM: -> @el

    # Convert
    toCSS: (debug) -> _cssFromObject @cssMap, debug

    # Convert
    toCSSMap: -> @cssMap

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

# oj.CollectionView
# ------------------------------------------------------------------------------
oj.CollectionView = oj.type 'CollectionView',
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

    models:
      get: -> @_models
      set: (v) ->
        # Unbind events if collection
        if oj.isFunction @_models?.off
          @_models.off 'add remove change reset destroy', null, @

        @_models = v

        # Bind events if collection
        if oj.isFunction @_models?.on
          @_models.on 'add', @collectionAdded, @
          @_models.on 'remove', @collectionRemoved, @
          @_models.on 'change', @collectionChanged, @
          @_models.on 'reset', @collectionReset, @
          @_models.on 'destroy', @collectionDestroyed, @

        @make() if @isConstructed

        return

  methods:
    # Override make to create your view
    make: -> throw "oj.#{typeName}: make not implemented"

    # Override these events to minimally update on change
    collectionAdded: (model, collection) -> @make()
    collectionRemoved: (model, collection, options) -> @make()
    collectionReset: (collection, options) -> @make()
    collectionChanged: (model, collection, options) -> # Do nothing
    collectionDestroyed: (collection, options) -> @make()

# oj.ModelView
# ------------------------------------------------------------------------------
# Model view base class
oj.ModelView = oj.type 'ModelView',
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
        if oj.isEvented @_model
          @_model.off 'change', null, @

        @_model = v;

        # Bind events on the new model
        if oj.isEvented @_model
          @_model.on 'change', @modelChanged, @

        # Trigger change manually when settings new model
        @modelChanged()
        return

  methods:

    # Override modelChanged if you don't want a full remake
    modelChanged: ->
      @$el.oj =>
        @make @mode

    make: (model) -> throw "oj.#{@typeName}: make not implemented"

# oj.ModelKeyView
# ------------------------------------------------------------------------------
# Model key view base class
oj.ModelKeyView = oj.type 'ModelKeyView',
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

# oj.TextBox
# ------------------------------------------------------------------------------
# TextBox control

oj.TextBox = oj.type 'TextBox',

  base: oj.ModelKeyView

  constructor: ->
    {options, args} = oj.argumentsUnion arguments

    @el = oj =>
      oj.input type:'text',
        keydown: => if @live then @viewChanged(); return
        keyup: => if @live then @viewChanged(); return
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

# oj.CheckBox
# ------------------------------------------------------------------------------
# CheckBox control

oj.CheckBox = oj.type 'CheckBox',
  base: oj.ModelKeyView

  constructor: ->
    {options, args} = oj.argumentsUnion arguments

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

# oj.TextArea
# ------------------------------------------------------------------------------
# TextArea control

oj.TextArea = oj.type 'TextArea',
  base: oj.ModelKeyView

  constructor: ->
    {options, args} = oj.argumentsUnion arguments

    @el = oj =>
      oj.textarea
        keydown: => if @live then @viewChanged(); return
        keyup: => if @live then @viewChanged(); return
        change: => @viewChanged(); return

    # Value can be set by argument
    @value = args[0] if args.length > 0

    oj.TextArea.base.constructor.call @, options

  properties:
    value:
      get: -> @el.value
      set: (v) -> @el.value = v; return

    # Live update model as text changes
    live: true

# oj.ListBox
# ------------------------------------------------------------------------------
# ListBox control

oj.ListBox = oj.type 'ListBox',
  base: oj.ModelKeyView

  constructor: ->
    {options, args} = oj.argumentsUnion arguments

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
        throw new Error('oj.ListBox::options array is missing') unless oj.isArray v
        @_options = v
        @$el.oj ->
          for op in v
            oj.option op
          return
        return

# oj.Button
# ------------------------------------------------------------------------------
# Button control

oj.Button = oj.type 'Button',
  base: oj.View

  constructor: (args) ->
    {options, args} = oj.argumentsUnion arguments

    # Label is first argument
    options.label ?= if args.length > 0 then args[0] else ''

    @el = oj =>
      oj.button options.label

    oj.Button.base.constructor.apply @, [options]

# oj.Link
# ------------------------------------------------------------------------------
# oj.Link = class Link inherits Control

# oj.List
# ------------------------------------------------------------------------------

# boundOrThrow: Determine if the index is in range after negative correction
# When out of bounds an error message is thrown

boundOrThrow = (ix, count, message) ->
  # Correct negative indexes to be in range
  ixNew = if ix < 0 then ix + count else ix
  unless 0 <= ixNew and ixNew < count
    throw new Error(message + " is out of bounds (#{ix} in [0,#{count-1}])")
  ixNew

oj.List = oj.type 'List',
  base: oj.CollectionView

  constructor: ->
    # console.log "List constructor: ", arguments
    {options, args} = oj.argumentsUnion arguments

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

  properties:

    # items: get or set all items at once (readwrite)
    items:
      # Used cached items or items as interpreted by ojValue jquery plugin
      get: ->
        return @_items if @_items?
        v = @$itemsEl.ojValue()
        if oj.isArray v then v else [v]

      set: (v) -> @_items = v; @make(); return

    count: get: -> @$itemsEl.length

    # tagName: name of root tag
    tagName: get: -> @_tagName ? 'div'

    # itemTagName: name of item tags
    itemTagName:
      get: -> @_itemTagName ? 'div'
      set: (v) -> @_itemTagName = v; @make(); return

    # itemsEl: list of elements
    itemsEl: get: -> @$itemsEl.get()

    # $itemsEl: list of jquery elements
    $itemsEl: get: -> @_$itemsEl ? (@_$itemsEl = @$("> #{@itemTagName}"))

  methods:
    # Get item value at index
    item: (ix, ojml) ->
      ix = boundOrThrow ix, @count, "oj.List.item: index"
      if ojml?
        @$itemEl(ix).oj ojml
        return
      else
        @$itemEl(ix).ojValue()

    # Get item element at index
    itemEl: (ix) ->
      ix = boundOrThrow ix, @count, "oj.List.itemEl: index"
      @$itemsEl[ix]

    # Get item jquery element at index
    $itemEl: (ix) ->
      ix = boundOrThrow ix, @count, "oj.List.$itemEl: index"
      @$itemsEl.eq(ix)

    # Remake everything
    make: ->
      # Some properties call make before construction completes
      return unless @isConstructed

      # Convert models to views
      views = []
      if @models? and @each?
        models = if oj.isEvented @_models then @_models.models else @_models
        for model in models
          views.push @_itemFromModel model

      # Items are already views
      else if @items?
        views = @items

      # Render the views
      @$el.oj =>
        for view in views
          @_itemElFromItem view

      @itemsChanged()
      return

    # Helper to map model to item
    _itemFromModel: (model) ->
      oj =>
        @each model

    # Helper to create itemTagName wrapped item
    _itemElFromItem: (item) ->
      oj[@itemTagName] item

    add: (ix, ojml) ->

      # Default to adding at the end
      if arguments.length == 1
        ojml = ix
        ix = @count

      ix = boundOrThrow ix, @count+1, "oj.List.add: index"

      tag = @itemTagName
      # Empty
      if @count == 0
        @$el.oj -> oj[tag] ojml
      # Last
      else if ix == @count
        @$itemEl(ix-1).ojAfter -> oj[tag] ojml
      # Not last
      else
        @$itemEl(ix).ojBefore -> oj[tag] ojml

      @itemsChanged()
      return

    remove: (ix = -1) ->
      ix = boundOrThrow ix, @count, "oj.List.remove: index"
      out = @item ix
      @$itemEl(ix).remove()
      @itemsChanged()
      out

    move: (ixFrom, ixTo = -1) ->
      return if ixFrom == ixTo

      ixFrom = boundOrThrow ixFrom, @count, "oj.List.move: fromIndex"
      ixTo = boundOrThrow ixTo, @count, "oj.List.move: toIndex"

      if ixTo > ixFrom
        @$itemEl(ixFrom).insertAfter @$itemEl(ixTo)
      else
        @$itemEl(ixFrom).insertBefore @$itemEl(ixTo)

      @itemsChanged()
      return

    swap: (ix1, ix2) ->
      return if ix1 == ix2

      ix1 = boundOrThrow ix1, @count, "oj.List.swap: firstIndex"
      ix2 = boundOrThrow ix2, @count, "oj.List.swap: secondIndex"

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

    push: (v) -> @add(v); return

    pop: -> @remove -1

    clear: -> @$itemsEl.remove(); @itemsChanged(); return

    # When items change clear relevant cached values
    itemsChanged: -> @_$itemsEl = null; return

    # # On add minimally create the missing model
    collectionAdded: (m, c) ->
      ix = c.indexOf m
      item = @_itemFromModel m
      @add ix, item
      return

    # On add minimally create the missing model
    collectionRemoved: (m, c, o) ->
      @remove o.index
      return

    collectionReset: ->
      @make()
      return

# oj.NumberList
# ------------------------------------------------------------------------------

oj.NumberList = ->
  oj.List.call @, {tagName:'ol', itemTagName:'li'}, arguments...

# oj.BulletList
# ------------------------------------------------------------------------------

oj.BulletList = ->
  oj.List.call @, {tagName:'ul', itemTagName:'li'}, arguments...

# oj.Table
# ------------------------------------------------------------------------------
# oj.Table = oj.type 'Table',
#   base: oj.CollectionView

#   properties:
#     rows: (list) ->
#     rowCount: ->
#     cellCount: ->

#   methods:
#     row: (r) ->
#     cell: (r, c) ->

# oj.Table.Row = oj.type 'Table.Row',
#   base: oj.ModelView
#   properties:
#     row:
#       get: ->
#       set: (list) ->
#   methods:
#     cell: ->

# oj.sandbox
# ------------------------------------------------------------------------------
# The sandbox is a readonly version of oj that is exposed to the user
oj.sandbox = {}
for key in _.keys oj
  if key.length > 0 and key[0] != '_'
    oj.addProperty oj.sandbox, key, value:oj[key], writable:false

# oj.use
# ------------------------------------------------------------------------------
# Include a plugin of oj

oj.use = (plugin, settings = {}) ->
  throw new Error('oj.use: function expected for first argument') unless oj.isFunction plugin
  throw new Error('oj.use: object expected for second argument') unless oj.isObject settings

  # Call plugin to gather extension map
  pluginMap = plugin oj, settings

  # Extend all properties
  for name,value of pluginMap
    oj[name] = value
    # Add to sandbox
    oj.addProperty oj.sandbox, name, value:value, writable: false


# jqueryExtend(fn)
# -----------------------------------------------------------------------------
#
#     $.fn.myExtension = jqueryExtend (($el,args) ->
#       $el     # => The jquery matched element
#       args    # => Array of arguments
#       return a non-null value to stop iteration and return value to caller
#      ), (($el) ->
#      ), isMap
jqueryExtend = (options = {}) ->
  _.defaults options, get:_.identity, set:_.identity
  ->
    args = _.toArray arguments
    $els = jQuery(@)
    # Map over jquery selection if no arguments
    if (oj.isFunction options.get) and args.length == 0
      out = []
      for el in $els
        out.push options.get $(el)
      # Unwrap arrays of length one
      if out.length == 1
        return out[0]
      out

    else if (oj.isFunction options.set)
      # By default return this for chaining
      out = $els
      for el in $els
        r = options.set $(el), args
        # Short circuit if anything is returned
        return r if r?

      $els

# jquery.oj
# -----------------------------------------------------------------------------
jQuery.fn.oj = jqueryExtend
  set:($el, args) ->

    # No arguments return the first instance
    if args.length == 0
      return $el[0].oj

    # Compile ojml
    {dom,types} = oj.compile {dom:1,html:0,css:0}, args...

    # Reset content and append to dom
    $el.html ''
    dom = [dom] unless oj.isArray dom
    for d in dom
      $el.append d

    # Call inserted event on all types
    for t in types
      t.inserted()

    return

  get: ($el) ->
    $el[0].oj

# jquery.ojValue
# -----------------------------------------------------------------------------
# Get the value of the selected element's contents
jQuery.fn.ojValue = jqueryExtend
  set: null
  get: ($el, args) ->

    el = $el[0]
    child = el.firstChild

    switch oj.typeOf child
      # Parse the text to turn it into bool, number, or string
      when 'dom-text'
        text = child.nodeValue
      # Get elements as oj instances or elements
      when 'dom-element'
        if (inst = _getInstanceOnElement child)?
          inst
        else
          child

# jquery.ojAfter, jquery.ojBefore, ...
# -----------------------------------------------------------------------------

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
    jQuery.fn[ojName] = jqueryExtend
      set: ($el, args) ->

        # Compile ojml for each one to separate references
        {dom,types} = oj.compile {dom:1,html:0}, args...

        # Append to the dom
        $el[jqName] dom

        for t in types
          t.inserted()

        return

      get:null





