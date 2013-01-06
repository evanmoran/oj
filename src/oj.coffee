
# oj
# ==============================================================================
# Unified templating framework for the people. Thirsty people.

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

# oj function
# ------------------------------------------------------------------------------
# Start oj by setting up dom and events
oj = module.exports = (page) ->
  # Compile
  compiled = oj.compile require page

  # Setup dom
  html = compiled.html
  throw new Error('oj: <html> element was not found') if html.indexOf('<html') != 0
  html = html.slice (html.indexOf '>')+1, html.lastIndexOf '<'
  (document.getElementsByTagName 'html')[0].innerHTML = html

  # Setup jquery events and awaken oj objects
  compiled.js()

  # Setup jquery ready and onload events
  oj.ready()
  oj.load()

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

# Register require.extension for .oj files
if require.extensions

  coffee = require 'coffee-script'
  fs = require new String('fs') # Hack to avoid pulling fs to client

  stripBOM = (c) -> if c.charCodeAt(0) == 0xFEFF then (c.slice 1) else c

  isCS = (code) -> -1 != code.search /(^\s*#|\n\s*#|-\>)/

  require.extensions['.oj'] = (module, filepath) ->
    # Compile as coffee-script or javascript
    code = stripBOM fs.readFileSync filepath, 'utf8'
    try
      code = coffee.compile code, bare: true
    catch eCoffee # js file, do nothing
      # If this is coffee script throw this error
      if isCS code
        eCoffee.message = "(coffee-script error) #{filepath}: #{eCoffee.message}"
        throw eCoffee

    # Compile javascript
    try
      code = "(function(){with(require('oj')){#{code}}}).call(this);"
      module._compile code, filepath

    catch eJS
      eJS.message = "(javascript error) #{filepath}: #{eJS.message}"
      throw eJS
    return

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


# Utility: Type Detection
# -----------------------

# _.isjQuery
_.isjQuery = (obj) -> !!(obj and obj.jquery)

# _.isBackbone
_.isBackbone = (obj) -> !!(obj and obj.on and obj.trigger and not _.isOJ obj)

# _.isOJ
# Determine if obj is an OJ instance
# TODO: Consider if this should be more duck typed on expected methods
_.isOJ = (obj) -> !!(obj and (_.isString obj.ojtype))

# Determine if object or array is empty
_.isEmpty = (obj) ->
  return obj.length == 0 if _.isArray obj
  for k of obj
    if _.has obj, k
      return false
  true

# typeOf: Mimic behavior of built-in typeof operator and integrate jQuery, Backbone, and OJ types
_.typeOf = (any) ->

  return 'null' if any == null
  t = typeof any
  if t == 'object'
    if _.isArray any           then t = 'array'
    else if _.isRegExp any     then t = 'regexp'
    else if _.isDate any       then t = 'date'
    else if _.isBackbone any   then t = 'backbone'
    else if _.isjQuery any     then t = 'jquery'
    else if _.isOJ any         then t = any.ojtype
    else                       t = 'object'
  t

# Determine if obj is a vanilla object
_.isObject = (obj) -> (_.typeOf obj) == 'object'

_.clone = (obj) ->
  # TODO: support cloning OJ instances
  # TODO: support options, deep: true
  return obj unless _.isObject obj
  if _.isArray obj then obj.slice() else _.extend {}, obj

# oj.create 'name',
#   methods:
#   properties:
#   events:

oj.type = (name, args) ->
  throw 'NYI'

  constructor = ->
    @_private = {}
    @_properties = args.properties
    @_methods = args.methods
    @_fields = args.fields

oj.enum = (name, args) ->
  throw 'NYI'


###
Type = oj.type 'Foo',
  methods:
    a: ->
    b: ->
      oj.super()
  properties:
    a:
      get:
    b:
      get:
      set:

type1 = new Type (arguments...)
type2 = new Type (backboneModel)  # will call toJSON() to construct

Type.addMethod(name, function)
Type.addProperty(name, definition)
Type.addStaticMethod(name, function)
Type.addStaticProperty(name, definition)
oj.type 'Type', extends: TypeBase,
###

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

# oj.partial (module, arg1, arg2, ...)
# ------------------------------------------------------------------------------
# Arguments are passed to exported module

oj.partial = (module, json) ->
  m = require module
  if (_.isFunction m) and arguments.length > 1
    return m arguments.slice(1)...
  m

# oj.tag (name, attributes, content, content, ...)
# ------------------------------------------------------------------------------
#     name          String of the tag to serialize
#     attributes    (Optional) Object defining attributes of tag being serialized
#                   Keys have smart mappings:
#                       'c'  will map to 'class'
#                       'fontSize' will map to 'font-size'
#                       'borderRadius' will map to 'moz-border-radius', etc.

oj._result = null

oj.tag = (name, args...) ->
  # console.log "calling oj.tag name: #{name}, args: ", args, ", result: ", oj._result
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

  # Push result. This is necessary to give the div -> syntax. It makes me sad.
  lastResult = oj._result

  # Loop over attributes
  for arg in args
    if _.isObject arg
      continue
    else if _.isFunction arg
      oj._result = ojml
      len = ojml.length

      # Call the argument it will auto append to _result which is ojml
      r = arg()

      # If nothing was changed push the result instead div(-> 1)
      if len == ojml.length and r?
        ojml.push r

    else
      ojml.push arg

  # Pop result and result self
  oj._result = lastResult
  if oj._result
    oj._result.push ojml
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

  options.html = if options.html then [] else null  # html accumulator
  options.js = []                                   # code accumulator
  options.types = []                                # types accumulator
  options.indent = ''                               # indent counter

  _compileAny ojml, options

  # Join html only if generated
  html = options.html?.join ''
  out = html: html, types: options.types, js:->
    # Call defered javascript
    for fn in options.js
      fn()
    # Call awaken for all objects
    for t in options.types
      t.awaken()
    undefined

  return out

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

  switch _.typeOf ojml

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
  throw new Error('oj.compile: tag is missing in array') unless _.isString(tag) and tag.length > 0

  # Create oj object if tag is capitalized
  if _.isCapitalLetter tag[0]
    return _compileDeeper _compileAny, (new oj[tag] ojml.slice(1)), options

  # Get attributes (optional)
  attributes = null
  if _.isObject ojml[1]
    attributes = ojml[1]

  children = if attributes then ojml.slice 2 else ojml.slice 1

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

  if children.length > 1
    for child in children
      if options.debug
        options.html?.push "\n\t#{options.indent}"
      _compileDeeper _compileAny, child, options
    if options.debug
      options.html?.push "\n#{options.indent}"
  else
    for child in children
      _compileDeeper _compileAny, child, options

  # End tag if you have children or your tag closes
  if children.length > 0 or oj.tag.isClosed(tag)
    options.html?.push "</#{tag}>"

# oj.make
# ------------------------------------------------------------------------------
# Make oj directly in the DOM

oj.make = (options, ojml) ->
  _.extend options,
    dom: true
    html: false
  result = oj.compile options, ojml
  result.js()
  result.dom

# oj.Control
# ------------------------------------------------------------------------------
# Properties
#   $             gets root element
#   set           Initialize from element, $(selector), or ojml

# Methods
#   constructor   Called when object is first constructed
#   initialize    Called when object is serialized into dom
#   parse         Called when object is being constructed     (need this?)
#   ojml          Property to set or get ojml of this object. Will reinitialize if set
#   toJSON        Alias for ojml get method

oj.Control = class Control

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

