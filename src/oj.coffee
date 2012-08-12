
# oj
# ====================================================================
# Templating framework for the people. Thirsty people.

oj = module.exports
oj.version = '0.0.0'

# Utility: Helpers
# ----------------

# Methods borrowed from [underscore.js](http://underscorejs.org/)
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
  if Array.prototype.forEach and col.forEach == Array.prototype.forEach
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
    console.log 'map2 option.recurse is true'
    do (options) ->
      options_ = _.clone options
      iterator_ = (v,k,o) ->
        console.log 'iterator_ called with v: ', v, ' k: ', k
        options__ = _.extend (_.clone options_), (key: k, object: v)
        _.map v, iterator, options__

  # Evaluate functions if necessary
  if _.isFunction obj

    # Functions pass through if evaluate isn't set
    return obj unless evaluate

    console.log 'map2 found a function'
    while evaluate and _.isFunction obj
      obj = obj()

  out = obj

  # Array case
  if _.isArray obj
    out = []
    return out unless obj
    return (obj.map iterator_, context) if Array.prototype.map and obj.map == Array.prototype.map
    console.log 'map found array'
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
    console.log 'map2 found value: ', obj
    return iterator.call context, obj, options.key, options.object,
  out

# _.extend
_.extend = (obj) ->
  _.each(Array.prototype.slice.call(arguments, 1), ((source) ->
    for key, value of source
      obj[key] = value
  ))
  obj

# _.defaults
_.defaults = (obj) ->
  _.each(Array.prototype.slice.call(arguments, 1), ((source) ->
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

oj.tag = (name, attributes, contents) ->
  throw 'oj.tag error: argument 1 is not a string (expected tag name)' unless _.isString name

  # If options isn't an object push it into contents
  if not _.isObject attributes
    contents.unshift attributes

  ojml = {oj: name}

  # Magic here!

  ojml

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
