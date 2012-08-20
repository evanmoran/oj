
# oj
# ====================================================================
# Templating framework for the people. Thirsty people.

oj = module.exports
oj.version = '0.0.0'

# Utility: Helpers
# ----------------

ArrayP = Array.prototype
FuncP = Function.prototype
ObjP = Object.prototype

slice = ArrayP.slice
unshift = ArrayP.unshift

# Methods from [underscore.js](http://underscorejs.org/), because some methods just need to exist.
oj._ = _ = {}
_.isUndefined = (obj) -> obj == undefined
_.isBoolean = (obj) -> obj == true or obj == false or toString.call(obj) == '[object Boolean]'
_.isNumber = (obj) -> !!(obj == 0 or (obj and obj.toExponential and obj.toFixed))
_.isString = (obj) -> !!(obj == '' or (obj and obj.charCodeAt and obj.substr))
_.isDate = (obj) -> !!(obj and obj.getTimezoneOffset and obj.setUTCFullYear)
_.isRegExp = (obj) -> toString.call(obj) == '[object RegExp]'
_.isFunction = (obj) -> typeof obj == 'function'
_.isArray = Array.isArray or (obj) -> toString.call(obj) == '[object Array]'
_.isElement = (obj) -> !!(obj and obj.nodeType == 1)
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

# Utility: Type Detection
# -----------------------

# _.isjQuery
_.isjQuery = (obj) -> !!(obj and obj.jquery)

# _.isBackbone
_.isBackbone = (obj) -> !!(obj and obj.on and obj.trigger and not _.isOJ obj)

# _.isOJ
# Determine if obj is an OJ instance
_.isOJ = (obj) -> !!(obj and _.isString obj.ojtype)

# Determine if obj is OJML instance
_.isOJML = (obj) -> !!(obj and _.isString obj.oj)

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
    else if _.isOJML any       then t = 'ojml'
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

oj.create = (name) ->
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

# oj.tag (name, attributes, content, content, ...)
# ----------------------------------------------------------------------------------------
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

  # Get attributes
  attributes = {}
  if args.length > 0 and _.isObject args[0]
    attributes = args.shift()

  # Build ojml starting with tag
  ojml = [name]

  # Add attributes to ojml if they exist
  ojml.push attributes unless _.isEmpty attributes

  # Push result. This is necessary to give the div -> syntax. It makes me
  # sad but it is very elegant.
  lastResult = oj._result

  # Loop over attributes
  for arg in args
    if _.isFunction arg
      oj._result = ojml
      len = ojml.length

      # Call the argument it will auto append to _result which is ojml
      r = arg()

      # If nothing was changed push the result instead div(-> 1)
      if len == ojml.length
        ojml.push r

    else
      ojml.push arg

  # Pop result and result self
  oj._result = lastResult
  if oj._result
    oj._result.push ojml
  ojml

oj.tag.elements =
  closed: 'aa abbr acronym address applet article aside audio b bdo big blockquote body button canvas caption center cite code colgroup command datalist dd del details dfn dir div dl dt em embed fieldset figcaption figure font footer form frameset h1 h2 h3 h4 h5 h6 head header hgroup html i iframe ins keygen kbd label legend li map mark menu meter nav noframes noscript object ol optgroup option output p pre progress q rp rt ruby s samp script section select small source span strike strong style sub summary sup table tbody td textarea tfoot th thead time title tr tt u ul var video wbr xmp'.split ' '
  open: 'area base br col command embed hr img input keygen link meta param source track wbr'.split ' '

oj.tag.elements.all = (oj.tag.elements.closed.concat oj.tag.elements.open).sort()

# Create tag methods
for t in oj.tag.elements.all
  do (t) ->
    oj[t] = -> oj.tag t, arguments...

# oj.extend (context)
# ----------------------------------------------------------------------------------------
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
