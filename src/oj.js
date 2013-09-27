// oj
// ===================================================================
// A unified templating framework for the people. Thirsty people.
// ---
(function(){
  var ArrP, FunP, ObjP, concat, dhp, exports, jqName, key, ojName, pass, plugins, root, slice, strict4, strict5, t, typeName, unshift, w3, _a, _argsStack, _attributesBindEventsToDOM, _attributesFromObject, _attributesProcessedForOJ, _clone, _compileAny, _compileDeeper, _compileTag, _construct, _createQuietType, _cssFromMediaObject, _cssFromPluginObject, _dasherize, _decamelize, _doctypes, _extend, _flattenCSSMap, _flattenCSSMap_, _fn, _fn1, _getInstanceOnElement, _getQuietTagName, _getTagName, _has, _i, identity, _inherit, _insertStyles, _isCapitalLetter, _isEmpty, _j, _jqExtend, _jqGetValue, _keys, _len, _len1, _onLoadQueue, _pathNormArray, _pathRx, _pathSplit, _ref, _ref1, _ref2, _setInstanceOnElement, _setObject, _setTagName, _splitAndTrim, _styleClassFromPlugin, _styleFromObject, _toArray, _triggerTypes, _undef = 'undefined', _uniqueSort, _v, _values,
    __slice = [].slice;

  root = this;

  // oj function
  // ---
  // oj function acts like a tag method that doesn't emit

  function oj(){return oj.tag.apply(this, ['oj'].concat([].slice.call(arguments)).concat([{__quiet__:1}]));};

  oj.version = '0.2.0'

  oj.isClient = !(typeof process !== "undefined" && process !== null ? process.versions != null ? process.versions.node : 0 : 0)

  // Detect jQuery globally or in required module
  if (typeof $ != _undef)
    oj.$ = $
  else if (typeof require != _undef)
    try {
      oj.$ = require('jquery')
    } catch (e){}

  // Export as a module in node
  if (typeof require != _undef)
    exports = module.exports = oj;
  // Export globally if not in node
  else
    root['oj'] = oj;

  // Reference ourselves for template files to see
  oj.oj = oj;

  // oj.load
  // ---
  // Load the page specified generating necessary html, css, and client side events.

  oj.load = function(page){
    // Defer dom manipulation until the page is ready
    return oj.$(function(){
      oj.$.ojBody(require(page));
      // Trigger events bound through onload

      return oj.onload();
    });
  };

  // oj.onload
  // ---
  // Enlist in onload action.

  _onLoadQueue = {queue: [], loaded: false}

  oj.onload = function(f){
    // Call everything if no arguments
    if (oj.isUndefined(f)){
      _onLoadQueue.loaded = true
      while ((f = _onLoadQueue.queue.shift()))
        f()
    }
    // Call load if already loaded
    else if (_onLoadQueue.loaded)
      f()
    // Queue function for later
    else
      _onLoadQueue.queue.push(f)
  }

  // oj.emit
  // ---
  // Used by plugins to group multiple elements as if it is a single tag.

  oj.emit = function(){
    return oj.tag.apply(oj, ['oj'].concat(__slice.call(arguments)));
  }

  ArrP = Array.prototype
  FunP = Function.prototype
  ObjP = Object.prototype
  slice = ArrP.slice
  unshift = ArrP.unshift
  concat = ArrP.concat
  identity = pass = function(v){return v}

  // Type Helpers
  // ---

  oj.isDefined = function(a){return typeof a !== _undef}
  oj.isOJ = function(obj){return !!(obj != null ? obj.isOJ : void 0)}
  oj.isOJType = function(a){return oj.isOJ(a) && a.type === a}
  oj.isOJInstance = function(a){return oj.isOJ(a) && !oj.isOJType(a)}
  oj.isEvented = function(a){return !!(a && a.on && a.off && a.trigger)}
  oj.isDOM = function(a){return !!(a && (a.nodeType != null))}
  oj.isDOMElement = function(a){return !!(a && a.nodeType === 1)}
  oj.isDOMAttribute = function(a){return !!(a && a.nodeType === 2)}
  oj.isDOMText = function(a){return !!(a && a.nodeType === 3)}
  oj.isjQuery = function(a){return !!(a && a.jquery)}
  oj.isUndefined = function(a){return a === void 0}
  oj.isBoolean = function(a){return a === true || a === false || ObjP.toString.call(a) === '[object Boolean]'}
  oj.isNumber = function(a){return !!(a === 0 || (a && a.toExponential && a.toFixed))}
  oj.isString = function(a){return !!(a === '' || (a && a.charCodeAt && a.substr))}
  oj.isDate = function(a){return !!(a && a.getTimezoneOffset && a.setUTCFullYear)}
  oj.isPlainObject = function(a){return oj.$.isPlainObject(a) && !oj.isOJ(a)}
  oj.isFunction = oj.$.isFunction
  oj.isArray = oj.$.isArray
  oj.isRegEx = function(a){return ObjP.toString.call(a) === '[object RegExp]'}
  oj.isArguments = function(a){return ObjP.toString.call(a) === '[object Arguments]'}
  oj.parse = function(str){
    var n, o = str
    if (str === _undef)
      o = void 0
    else if (str === 'null')
      o = null
    else if (str === 'true')
      o = true
    else if (str === 'false')
      o = false
    else if (!(isNaN(n = parseFloat(str))))
      o = n
    return o;
  };

  // Utility Helpers
  // ---

  _isCapitalLetter = function(c){return !!(c.match(/[A-Z]/));};

  _has = function(obj, key){return ObjP.hasOwnProperty.call(obj, key)}

  _keys = Object.keys

  _values = function(obj){var keys = _keys(obj);var length = keys.length; var values = new Array(length); for (var i = 0; i < length; i++){values[i] = obj[keys[i]]; } return values}

  _toArray = function(obj){
    if (!obj)
      return []
    if (oj.isArray(obj))
      return slice.call(obj)
    if (oj.isArguments(obj))
      return slice.call(obj)
    if (obj.toArray && oj.isFunction(obj.toArray))
      return obj.toArray()
    return _values(obj)
  }


  // _isEmpty: Determine if object or array is empty
  _isEmpty = function(obj){
    if (oj.isArray(obj))
      return obj.length === 0
    for (var k in obj){
      if (_has(obj, k))
        return false
    }
    return true
  };

  // _clone
  _clone = function(obj){
    if (!((oj.isArray(obj)) || (oj.isPlainObject(obj))))
      return obj
    if (oj.isArray(obj))
      return obj.slice()
    else
      return _extend({}, obj)
  }

  // _setObject: Set object deeply and ensure each part is an object
  _setObject = function(){
    var ix, k, keys, o, obj, value, _i, _j, _len;

    obj = arguments[0], keys = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), value = arguments[_i++];
    o = obj;
    for (ix = _j = 0, _len = keys.length; _j < _len; ix = ++_j){
      k = keys[ix];
      // Initialize key to empty object if necessary

      if (typeof o[k] !== 'object'){
        if (!(typeof o[k] === 'object')){
          o[k] = {};
        }
      }
      // Set final value if this is the last key

      if (ix === keys.length - 1){
        o[k] = value;
        break;
      }
      // Continue deeper

      o = o[k];
    }
    return obj;
  };

  // Functional Helpers
  // ---

  // _extend
  _extend = oj.$.extend;

  // _uniqueSort


  _uniqueSort = function(array, isSorted){
    var item, ix, out, _i, _len;

    if (isSorted == null){
      isSorted = false;
    }
    if (!isSorted){
      array.sort();
    }
    out = [];
    for (ix = _i = 0, _len = array.length; _i < _len; ix = ++_i){
      item = array[ix];
      if (ix > 0 && array[ix - 1] === array[ix]){
        continue;
      }
      out.push(item);
    }
    return out;
  };

  // Error Handling Helpers
  // ---
  // Assert cond is true or throw message

  _a = function(cond, msg, fn){
    if (!cond){
      if (fn){
        msg = "oj." + fn + ": " + msg;
      }
      throw new Error(msg);
    }
  };

  // Validate fn argument at position n matches type
  _v = function(fn, n, v, type){
    n = {
      1: 'first',
      2: 'second',
      3: 'third',
      4: 'fourth',
      5: 'fifth'
    }[n];
    _a(!type || (typeof v === type), "" + type + " expected for " + n + " argument", fn);
  };

  // String Helpers
  // ---
  // _splitAndTrim: Split string by seperator and trim result
  _splitAndTrim = function(str, seperator, limit){
    var r;

    r = str.split(seperator, limit);
    return r.map(function(v){
      return v.trim();
    });
  };

  // _dasherize: Convert from camal case or space seperated to dashes
  _dasherize = function(str){return _decamelize(str).replace(/[ _]/g, '-')}

  // _decamelize: Convert from camal case to underscore case
  _decamelize = function(str){return str.replace(/([a-z])([A-Z])/g, '$1_$2').toLowerCase()}

  // Path Helpers
  // ---
  // Used to implement require client side. These methods are simplified versions of
  // the node `path` library: github.com/joyent/node/lib/path.js

  _pathRx = /^(\/?)([\s\S]+\/(?!$)|\/)?((?:\.{1,2}$|[\s\S]+?)?(\.[^.\/]*)?)$/;

  _pathSplit = function(fname){
    var result = _pathRx.exec(fname)
    return [result[1] || '', result[2] || '', result[3] || '', result[4] || ''];
  };

  _pathNormArray = function(parts, allowAboveRoot){
    var i, last, up;

    up = 0;
    i = parts.length - 1;
    while (i >= 0){
      last = parts[i];
      if (last === '.'){
        parts.splice(i, 1);
      } else if (last === '..'){
        parts.splice(i, 1);
        up++;
      } else if (up){
        parts.splice(i, 1);
        up--;
      }
      i--;
    }
    if (allowAboveRoot){
      while (up--){
        parts.unshift('..');
      }
    }
    return parts;
  };

  oj._pathResolve = function(){
    var i, isAbsolute, path, resolvedPath;

    resolvedPath = '';
    isAbsolute = false;
    i = arguments.length - 1;
    while (i >= -1 && !isAbsolute){
      path = i >= 0 ? arguments[i] : process.cwd();
      if ((typeof path !== 'string') || !path){
        continue;
      }
      resolvedPath = path + '/' + resolvedPath;
      isAbsolute = path.charAt(0) === '/';
      i--;
    }
    resolvedPath = _pathNormArray(resolvedPath.split('/').filter(function(p){
      return !!p;
    }), !isAbsolute).join('/');
    return ((isAbsolute ? '/' : '') + resolvedPath) || '.';
  };

  oj._pathNormalize = function(path){
    var isAbsolute, trailingSlash;

    isAbsolute = path.charAt(0) === '/';
    trailingSlash = path.substr(-1) === '/';
    path = _pathNormArray(path.split('/').filter(function(p){
      return !!p;
    }), !isAbsolute).join('/');
    if (!path && !isAbsolute){
      path = '.';
    }
    if (path && trailingSlash){
      path += '/';
    }
    return (isAbsolute ? '/' : '') + path;
  };

  oj._pathJoin = function(){
    var paths;

    paths = slice.call(arguments, 0);
    return oj._pathNormalize(paths.filter(function(p, index){
      return p && typeof p === 'string';
    }).join('/'));
  };

  oj._pathDirname = function(path){
    var dir, result;

    result = _pathSplit(path);
    root = result[0];
    dir = result[1];
    if (!root && !dir){
      return '.';
    }
    if (dir){
      dir = dir.substr(0, dir.length - 1);
    }
    return root + dir;
  };

  // oj.addMethod


  // ---


  // Add multiple methods to an object


  oj.addMethods = function(obj, mapNameToMethod){
    var method, methodName;

    for (methodName in mapNameToMethod){
      method = mapNameToMethod[methodName];
      oj.addMethod(obj, methodName, method);
    }
  };

  // oj.addMethod


  // ---


  // Add method to an object


  oj.addMethod = function(obj, methodName, method){
    _v('addMethod', 2, methodName, 'string');
    _v('addMethod', 3, method, 'function');
    // Methods are non-enumerable, non-writable properties

    Object.defineProperty(obj, methodName, {
      value: method,
      enumerable: false,
      writable: false,
      configurable: true
    });
  };

  // oj.removeMethod
  // ---
  // Remove a method from an object
  oj.removeMethod = function(obj, methodName){
    _v('removeMethod', 2, methodName, 'string');
    delete obj[methodName];
  };

  // oj.addProperties
  // ---
  // Add multiple properties to an object
  // Properties can be specified by get/set methods or by a value

  // Value Property:
  // `age: 7    # defaults to {writable:true, enumerable:true}`

  // Value Property with specified writable/enumerable:
  // `age: {value:7, writable:false, enumerable:false}`

  // Readonly Get Property
  // `age: {get:(-> 7)}`

  oj.addProperties = function(obj, mapNameToInfo){

    // Iterate over properties
    var propInfo, propName;

    for (propName in mapNameToInfo){
      propInfo = mapNameToInfo[propName];

      // Wrap the value if propInfo is not already a property definition
      if (((propInfo != null ? propInfo.get : void 0) == null) && ((propInfo != null ? propInfo.value : void 0) == null)){
        propInfo = {
          value: propInfo,
          writable: true
        };
      }
      oj.addProperty(obj, propName, propInfo);
    }
  };

  // oj.addProperty
  // ---

  oj.addProperty = function(obj, propName, propInfo){
    _v('addProperty', 2, propName, 'string');
    _v('addProperty', 3, propInfo, 'object');

    // Default properties to enumerable and configurable
    propInfo = _extend({
      enumerable: true,
      configurable: true
    }, propInfo);

    // Remove property if it already exists
    if (Object.getOwnPropertyDescriptor(obj, propName) != null){
      oj.removeProperty(obj, propName);
    }

    // Add the property
    Object.defineProperty(obj, propName, propInfo);
  };

  // oj.removeProperty
  // ---

  oj.removeProperty = function(obj, propName){
    _v('removeProperty', 2, propName, 'string');
    delete obj[propName];
  };

  // oj.isProperty
  // ---
  // Determine if the specified key is was defined by addProperty

  oj.isProperty = function(obj, propName){
    _v('isProperty', 2, propName, 'string');
    return Object.getOwnPropertyDescriptor(obj, propName).get != null;
  };

  // oj.copyProperty
  // ---
  // Determine copy source.propName to dest.propName

  oj.copyProperty = function(dest, source, propName){
    var info = Object.getOwnPropertyDescriptor(source, propName);
    if (info.value != null){
      info.value = _clone(info.value);
    }
    return Object.defineProperty(dest, propName, info);
  };

  // _argsStack
  // ---
  // Abstraction to wrap global arguments stack. This makes me sad but it is necessary for div -> syntax

  // Stack of results
  _argsStack = [];

  // Result is top of the stack
  oj._argsTop = function(){
    if (_argsStack.length)
      return _argsStack[_argsStack.length - 1]
    else
      return null
  }

  // Push scope onto arguments
  oj._argsPush = function(args){
    if (args == null)
      args = []
    _argsStack.push(args)
  }

  // Pop scope from arguments
  oj._argsPop = function(){
    if (_argsStack.length)
      return _argsStack.pop()
    return null
  }

  // Append argument
  oj._argsAppend = function(arg){
    var top = oj._argsTop()
    if (top != null)
      top.push(arg)
  }

  // oj.tag (name, attributes, content, content, ...)
  // ---
  oj.tag = function(){
    var arg, args, attributes, isQuiet, len, name, ojml, r, rest, _i, _len, _ref1;

    name = arguments[0], rest = 2 <= arguments.length ? __slice.call(arguments, 1) : [];

    // Validate input
    _v('tag', 1, name, 'string');

    // Build ojml starting with tag
    ojml = [name];

    // Get attributes from rest by unioning all objects
    _ref1 = oj.unionArguments(rest), args = _ref1.args, attributes = _ref1.options;
    if (isQuiet = attributes.__quiet__)
      delete attributes.__quiet__;

    // Add attributes to ojml if they exist
    if (!_isEmpty(attributes))
      ojml.push(attributes);

    // Store current tag context
    oj._argsPush(ojml);

    // Loop over attributes
    for (_i = 0, _len = args.length; _i < _len; _i++){
      arg = args[_i];

      if (oj.isPlainObject(arg))
        continue;

      else if (oj.isFunction(arg)){
        len = oj._argsTop().length;

        // Call the fn tags will append to oj._argsTop
        r = arg()

        // Use return value instead if oj._argsTop didn't change
        if (len === oj._argsTop().length && (r != null))
          oj._argsAppend(r)

      } else
        oj._argsAppend(arg)
    }

    // Restore previous tag context
    oj._argsPop()

    // Append the final result to your parent's arguments
    // if there exists an argument to append to.
    // Do not emit when quiet is set,
    if (!isQuiet)
      oj._argsAppend(ojml)

    return ojml
  }

  // Define all elements as closed or open
  oj.tag.elements = {
    closed: 'a abbr acronym address applet article aside audio b bdo big blockquote body button canvas caption center cite code colgroup command datalist dd del details dfn dir div dl dt em embed fieldset figcaption figure font footer form frameset h1 h2 h3 h4 h5 h6 head header hgroup html i iframe ins keygen kbd label legend li map mark menu meter nav noframes noscript object ol optgroup option output p pre progress q rp rt ruby s samp script section select small source span strike strong style sub summary sup table tbody td textarea tfoot th thead time title tr tt u ul var video wbr xmp'.split(' '),
    open: 'area base br col command css !DOCTYPE embed hr img input keygen link meta param source track wbr'.split(' ')
  }

  // Keep track of all valid elements
  oj.tag.elements.all = (oj.tag.elements.closed.concat(oj.tag.elements.open)).sort()

  // Determine if an element is closed or open
  oj.tag.isClosed = function(tag){
    return oj.tag.elements.open.indexOf(tag) === -1
  }

  // Record tag name on a given tag function
  _setTagName = function(tag, name){
    if (tag != null)
      tag.tagName = name
  }

  // Get a tag name on a given tag function
  _getTagName = function(tag){
    return tag.tagName;
  }

  // Get quiet tag name
  _getQuietTagName = function(tag){
    return '_' + tag;
  }

  // Record an oj instance on a given element
  _setInstanceOnElement = function(el, inst){
    if (el != null)
      el.oj = inst
  }

  // Get a oj instance on a given element
  _getInstanceOnElement = function(el){
    if ((el != null ? el.oj : 0) != null)
      return el.oj
    else
      return null
  }

  // Create tag methods for all elements
  _ref1 = oj.tag.elements.all;
  _fn = function(t){
    // Tag functions emit by default
    var qt;

    oj[t] = function(){
      return oj.tag.apply(oj, [t].concat(__slice.call(arguments)));
    };

    // Underscore tag functions do not emit
    qt = _getQuietTagName(t);
    oj[qt] = function(){
      return oj.tag.apply(oj, [t, {
        __quiet__: 1
      }].concat(__slice.call(arguments)));
    };

    // Record the tag name so the OJML syntax can use the function instead of a string
    _setTagName(oj[t], t);
    return _setTagName(oj[qt], t);
  };

  for (_i = 0, _len = _ref1.length; _i < _len; _i++){
    t = _ref1[_i];
    _fn(t);
  }

  // oj.doctype
  // ---
  // Method to define doctypes based on short names
  // Define helper variables

  dhp = 'HTML PUBLIC "-//W3C//DTD HTML 4.01'
  w3 = '"http://www.w3.org/TR/html4/'
  strict5 = 'html'
  strict4 = dhp + '//EN" ' + w3 + 'strict.dtd"'

  // Define possible arguments
  _doctypes = {
    '5': strict5,
    'HTML 5': strict5,
    '4': strict4,
    'HTML 4.01 Strict': strict4,
    'HTML 4.01 Frameset': dhp + ' Frameset//EN" ' + w3 + 'frameset.dtd"',
    'HTML 4.01 Transitional': dhp + ' Transitional//EN" ' + w3 + 'loose.dtd"'
  }

  // Define the method passing through to !DOCTYPE tag function
  oj.doctype = function(typeOrValue){
    var value, _ref2;

    if (typeOrValue == null){
      typeOrValue = '5';
    }
    value = (_ref2 = _doctypes[typeOrValue]) != null ? _ref2 : typeOrValue;
    return oj['!DOCTYPE'](value);
  };

  // oj.extendInto (context)
  // ---
  // Extend all OJ methods into a context. Common contexts are `global` `window`

  // Methods that start with _ are not extended
  oj.useGlobally = oj.extendInto = function(context){
    var k, o, qn, v;

    if (context == null)
      context = root

    o = {}
    for (k in oj){
      v = oj[k];
      if (k[0] !== '_' && k !== 'extendInto' && k !== 'useGlobally'){
        o[k] = v;

        // Export _tag and _Type methods
        qn = _getQuietTagName(k);
        if (oj[qn])
          o[qn] = oj[qn]

      }
    }
    return _extend(context, o)
  };

  // oj.compile(options, ojml)
  // ---
  // Compile ojml into meaningful parts
  // options:
  // * html - Compile to html
  // * dom - Compile to dom
  // * css - Compile to css
  // * cssMap - Record css as a javascript object
  // * styles -- Output css as style tags
  // * minify - Minify js and css
  // * ignore:{html:1} - Map of tags to ignore while compiling

  oj.compile = function(options, ojml){
    var acc, css, cssMap, dom, html, pluginCSSMap;

    // Options is optional
    if (ojml == null){
      ojml = options;
      options = {};
    }

    // Default options to compile everything
    options = _extend({
      html: true,
      dom: false,
      css: false,
      cssMap: false,
      minify: false,
      ignore: {}
    }, options);

    // Always ignore oj and css tags
    _extend(options.ignore, {
      oj: 1,
      css: 1
    });
    acc = _clone(options);
    acc.html = options.html ? [] : null;
    acc.dom = options.dom && (typeof document !== "undefined" && document !== null) ? document.createElement('OJ') : null;
    acc.css = options.css || options.cssMap ? {} : null;
    acc.indent = '';
    if (options.dom)
      acc.types = [];

    acc.tags = {};
    _compileAny(ojml, acc);

    if (acc.css != null)
      pluginCSSMap = _flattenCSSMap(acc.css)

    // Output cssMap if necessary
    if (options.cssMap)
      cssMap = pluginCSSMap;

    // Generate css if necessary
    if (options.css){
      css = _cssFromPluginObject(pluginCSSMap, {
        minify: options.minify,
        tags: 0
      });
    }

    // Generate HTML if necessary
    if (options.html)
      html = acc.html.join('')

    // Generate dom if necessary
    if (options.dom){

      // Remove the <oj> wrapping from the dom element
      dom = acc.dom.childNodes;

      // Cleanup inconsistencies of childNodes
      if (dom.length != null){
        // Make dom a real array

        dom = _toArray(dom);

        // Filter out anything that isn't a dom element
        dom = dom.filter(function(v){
          return oj.isDOM(v);
        });
      }

      // Ensure dom is null if empty
      if (dom.length === 0)
        dom = null
      else if (dom.length === 1)

        // Single elements are returned themselves not as a list
        // Reasoning: The common cases don't have multiple elements <html>,<body>

        // or the complexity doesn't matter because insertion is abstracted for you

        // In short it is easier to check for isArray dom, then isArray dom && dom.length > 0

        dom = dom[0];

    }
    return {
      html: html,
      dom: dom,
      css: css,
      cssMap: cssMap,
      types: acc.types,
      tags: acc.tags
    }
  };

  // _styleFromObject:
  // ---
  // Convert object to style string
  _styleFromObject = function(obj, options){
    var indent, ix, k, kFancy, keys, newline, out, semi, _j, _len1, _ref2;

    if (options == null){
      options = {};
    }

    // Default options
    options = _extend({
      inline: true,
      indent: ''
    }, options);

    // Trailing semi should only exist on when we aren't indenting
    options.semi = !options.inline;
    out = "";

    // Sort keys to create consistent output
    keys = _keys(obj).sort();

    // Support indention and inlining
    indent = (_ref2 = options.indent) != null ? _ref2 : '';
    newline = options.inline ? '' : '\n';
    for (ix = _j = 0, _len1 = keys.length; _j < _len1; ix = ++_j){
      kFancy = keys[ix];

      // Add semi if it is not inline or it is not the last key
      semi = options.semi || ix !== keys.length - 1 ? ";" : '';
      // Allow keys to be camal case

      k = _dasherize(kFancy);

      // Collect css result for this key
      out += "" + indent + k + ":" + obj[kFancy] + semi + newline;
    }
    return out;
  };

  // _attributesFromObject: Convert object to attribute string
  // ---
  // This object has nothing special. No renamed keys, no jquery events. It is
  // precicely what must be serialized with no adjustment.

  _attributesFromObject = function(obj){

    // Pass through non objects
    var k, out, space, v, _j, _len1, _ref2;

    if (!oj.isPlainObject(obj)){
      return obj;
    }
    out = '';

    // Serialize attributes in order for consistent output
    space = '';
    _ref2 = _keys(obj).sort();
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++){
      k = _ref2[_j];
      v = obj[k];
      // Boolean attributes have no value
      if (v === true)
        out += "" + space + k;
      // Other attributes have a value
      else
        out += "" + space + k + "=\"" + v + "\"";

      space = ' ';
    }
    return out;
  };

  // _flattenCSSMap
  // ---
  // Take an OJ object definition of CSS and simplify it to the form:
  // `'plugin' -> '@media query' -> 'selector' ->'rulesMap'`
  // This method vastly simplifies `_cssFromPluginObject`
  // Nested definitions, media definitions and comma definitions are resolved.

  _flattenCSSMap = function(cssMap){
    var cssMap_, flatMap, plugin;

    flatMap = {};
    for (plugin in cssMap){
      cssMap_ = cssMap[plugin];
      _flattenCSSMap_(cssMap_, flatMap, [''], [''], plugin);
    }
    return flatMap;
  };

  // Recursive helper with accumulators (it outputs flatMapAcc)
  _flattenCSSMap_ = function(cssMap, flatMapAcc, selectorsAcc, mediasAcc, plugin){

    // Built in media helpers
    var acc, cur, inner, isMedia, mediaJoined, medias, mediasNext, next, outer, parts, rules, selector, selectorJoined, selectorsNext, _j, _k, _len1, _len2;

    medias = {
      'widescreen': 'only screen and (min-width: 1200px)',
      'monitor': '',
      'tablet': 'only screen and (min-width: 768px) and (max-width: 959px)',
      'phone': 'only screen and (max-width: 767px)'
    };
    for (selector in cssMap){
      rules = cssMap[selector];

      // Base Case: Record our selector when `rules` is a value
      if (typeof rules !== 'object'){

        // Join selectors and media accumulators with commas
        selectorJoined = selectorsAcc.sort().join(',');
        mediaJoined = mediasAcc.sort().join(',');

        // Prepend @media as that was removed previously when spliting into parts
        if (mediaJoined !== ''){
          mediaJoined = "@media " + mediaJoined;
        }

        // Record the rule deeply in `flatMapAcc`
        _setObject(flatMapAcc, plugin, mediaJoined, selectorJoined, selector, rules);
      } else {

        // Recursive Case: Recurse on `rules` when it is an object
        // (r1) Media Query found: Generate the next media queries
        if (selector.indexOf('@media') === 0){
          isMedia = true;
          mediasNext = next = [];
          selectorsNext = selectorsAcc;
          selector = (selector.slice('@media'.length)).trim();
          acc = mediasAcc;
        } else {

          // (r2) Selector found: Generate the next selectors
          isMedia = false;
          selectorsNext = next = [];
          mediasNext = mediasAcc;
          acc = selectorsAcc;
        }

        // Media queries and Selectors can be comma seperated
        parts = _splitAndTrim(selector, ',');

        // Media queries have convience substitutions like 'phone', 'tablet'
        if (isMedia){
          parts = parts.map(function(v){
            if (medias[v] != null){
              return medias[v];
            } else {
              return v;
            }
          });
        }

        // Determine the next selectors or media queries
        for (_j = 0, _len1 = acc.length; _j < _len1; _j++){
          outer = acc[_j];
          for (_k = 0, _len2 = parts.length; _k < _len2; _k++){
            inner = parts[_k];

            // When `&` is not present just insert in front with the correct join operator
            cur = inner;
            if ((inner.indexOf('&')) === -1 && outer !== ''){
              cur = (isMedia ? '& and ' : '& ') + cur;
            }
            next.push(cur.replace(/&/g, outer));
          }
        }

        // Recurse through objects after calculating the next selectors
        _flattenCSSMap_(rules, flatMapAcc, selectorsNext, mediasNext, plugin);
      }
    }
  };

  // _styleClassFromPlugin:
  _styleClassFromPlugin = function(plugin){
    return "" + plugin + "-style";
  };

  // _styleTagFromMediaObject:
  oj._styleTagFromMediaObject = function(plugin, mediaMap, options){
    var css, newline;

    newline = (options != null ? options.minify : void 0) ? '' : '\n';
    css = _cssFromMediaObject(mediaMap, options);
    return "<style class=\"" + (_styleClassFromPlugin(plugin)) + "\">" + newline + css + "</style>";
  };

  // _cssFromMediaObject:
  // ---
  // Convert css from a flattened rule object. The rule object is of the form:

  // mediaQuery => selector => rulesObject
  // Placeholder functions for server side minification

  oj._minifyJS = function(js, options){return js}
  oj._minifyCSS = function(css, options){return css}

  _cssFromMediaObject = function(mediaMap, options){
    var css, eCSS, indent, indentRule, inline, media, minify, newline, rules, selector, selectorMap, space, styles, tags, _ref2, _ref3;

    if (options == null)
      options = {}

    minify = (_ref2 = options.minify) != null ? _ref2 : 0;
    tags = (_ref3 = options.tags) != null ? _ref3 : 0;

    // Deterine what output characters are needed
    newline = minify ? '' : '\n';
    space = minify ? '' : ' ';
    inline = minify;

    // Build css for media => selector =>  rules
    css = '';
    for (media in mediaMap){
      selectorMap = mediaMap[media];

      // Serialize media query
      if (media){
        media = media.replace(/,/g, "," + space);
        css += "" + media + space + "{" + newline;
      }

      for (selector in selectorMap){
        styles = selectorMap[selector];
        indent = (!minify) && media ? '\t' : '';

        // Serialize selector
        selector = selector.replace(/,/g, "," + newline);
        css += "" + indent + selector + space + "{" + newline;

        // Serialize style rules
        indentRule = !minify ? indent + '\t' : indent;
        rules = _styleFromObject(styles, {
          inline: inline,
          indent: indentRule
        });
        css += rules + indent + '}' + newline;
      }

      // End media query
      if (media !== '')
        css += '}' + newline

    }
    try {
      css = oj._minifyCSS(css, options);
    } catch (_error){
      eCSS = _error;
      throw new Error("css minification error: " + eCSS.message + "\nCould not minify:\n" + css);
    }
    return css
  };

  // _cssFromPluginObject:
  // ---
  // Convert flattened css selectors and rules to a string.
  // Plugin objects are of the form:
  // pluginName => mediaQuery => selector => rulesObject
  // minify:false will output newlines
  // tags:true will output the css in `<style>` tags

  _cssFromPluginObject = function(flatCSSMap, options){
    var css, inline, mediaMap, minify, newline, plugin, space, tags, _ref2, _ref3;

    if (options == null)
      options = {}

    minify = (_ref2 = options.minify) != null ? _ref2 : 0;
    tags = (_ref3 = options.tags) != null ? _ref3 : 0;

    // Deterine what output characters are needed
    newline = minify ? '' : '\n';
    space = minify ? '' : ' ';
    inline = minify;
    css = '';
    for (plugin in flatCSSMap){
      mediaMap = flatCSSMap[plugin];
      if (tags){
        css += "<style class=\"" + plugin + "-style\">" + newline;
      }

      // Serialize CSS with potential minification
      css += _cssFromMediaObject(mediaMap, options);
      if (tags)
        css += "" + newline + "</style>" + newline

    }
    return css;
  };

  // _compileDeeper
  // ---
  // Recursive helper for compiling that wraps indention

  _compileDeeper = function(method, ojml, options){
    var i = options.indent;
    options.indent += '\t';
    method(ojml, options);
    return options.indent = i;
  };

  // _compileAny
  // ---
  // Recursive helper for compiling any type
  // Compile ojml or any type

  _compileAny = function(any, options){
    var els, _ref10, _ref11, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;

    // Array
    if (oj.isArray(any))
      _compileTag(any, options)

    // String
    else if (oj.isString(any)){
      if ((_ref2 = options.html) != null)
        _ref2.push(any)

      if (any.length > 0 && any[0] === '<'){
        root = document.createElement('div');
        root.innerHTML = any;
        els = root.childNodes;
        if ((_ref3 = options.dom) != null){
          _ref3.appendChild(root);
        }
        // for el in els
        // options.dom?.appendChild el

      } else {
        if ((_ref4 = options.dom) != null){
          _ref4.appendChild(document.createTextNode(any));
        }
      }

    // Boolean or Number
    } else if (oj.isBoolean(any) || oj.isNumber(any)){
      if ((_ref5 = options.html) != null){
        _ref5.push("" + any);
      }
      if ((_ref6 = options.dom) != null){
        _ref6.appendChild(document.createTextNode("" + any));
      }

    // Function
    } else if (oj.isFunction(any)){

      // Wrap function call to allow full oj generation within any
      _compileAny(oj(any), options);

    // Date
    } else if (oj.isDate(any)){
      if ((_ref7 = options.html) != null){
        _ref7.push("" + (any.toLocaleString()));
      }
      if ((_ref8 = options.dom) != null){
        _ref8.appendChild(document.createTextNode("" + (any.toLocaleString())));
      }

    // OJ Type or Instance
    } else if (oj.isOJ(any)){
      if ((_ref9 = options.types) != null){
        _ref9.push(any);
      }
      if ((_ref10 = options.html) != null){
        _ref10.push(any.toHTML(options));
      }
      if ((_ref11 = options.dom) != null){
        _ref11.appendChild(any.toDOM(options));
      }
      if (options.css != null){
        _extend(options.css, any.toCSSMap(options));
      }
    }
    // Do nothing for: null, undefined, object

  };

  // _compileTag
  // ---
  // Recursive helper for compiling ojml tags

  _compileTag = function(ojml, options){
    var att, attr, attrName, attrValue, attributes, child, children, el, events, selector, space, styles, tag, tagType, _base, _base1, _j, _k, _len1, _len2, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;

    // Empty list compiles to undefined
    if (ojml.length === 0) return

    // Get tag name, allowing the tag parameter to be 'table' (tag name) or table (function) or Table (object)
    tag = ojml[0];
    tagType = typeof tag;
    tag = (tagType === 'function' || tagType === 'object') && (_getTagName(tag) != null) ? _getTagName(tag) : tag;
    if (!(oj.isString(tag) && tag.length > 0))
      throw new Error('oj.compile: tag name is missing');

    // Record tag as encountered
    options.tags[tag] = true;

    // Instance oj object if tag is capitalized
    if (_isCapitalLetter(tag[0]))
      return _compileDeeper(_compileAny, new oj[tag](ojml.slice(1)), options)

    // Gather attributes if present
    attributes = null;
    if (oj.isPlainObject(ojml[1])){
      attributes = ojml[1];
    }

    // Gather children if present
    children = attributes ? ojml.slice(2) : ojml.slice(1);

    // Compile to css if requested
    if (options.css && tag === 'css'){

      // Extend options.css with rules
      for (selector in attributes){
        styles = attributes[selector];
        if ((_ref2 = (_base = options.css)['oj']) == null)
          _base['oj'] = {};

        if ((_ref3 = (_base1 = options.css['oj'])[selector]) == null)
          _base1[selector] = {};

        _extend(options.css['oj'][selector], styles);
      }
    }

    // Compile DOCTYPE as special case because it is not really an element
    // It has attributes with spaces and cannot be created by dom manipulation
    // In this way it is HTML generation only.

    if (tag === '!DOCTYPE'){
      _v('compile', 1, ojml[1], 'string');
      if (!options.ignore[tag]){
        if (options.html){
          options.html.push("<" + tag + " " + ojml[1] + ">");
        }
        // options.dom is purposely ignored

      }
      return;
    }
    if (!options.ignore[tag]){
      events = _attributesProcessedForOJ(attributes);
      // Compile to dom if requested

      // Add dom element with attributes

      if (options.dom && (typeof document !== "undefined" && document !== null)){
        // Create element

        el = document.createElement(tag);
        // Add self to parent

        if (oj.isDOMElement(options.dom)){
          options.dom.appendChild(el);
        }
        // Push ourselves on the dom stack (to handle children)

        options.dom = el;
        // Set attributes in sorted order for consistency

        if (oj.isPlainObject(attributes)){
          _ref4 = _keys(attributes).sort();
          for (_j = 0, _len1 = _ref4.length; _j < _len1; _j++){
            attrName = _ref4[_j];
            attrValue = attributes[attrName];
            // Boolean attributes have no value

            if (attrValue === true){
              att = document.createAttribute(attrName);
              el.setAttributeNode(att);
            } else {
              el.setAttribute(attrName, attrValue);
            }
          }
        }
        // Bind events

        _attributesBindEventsToDOM(events, el);
      }
      // Compile to html if requested

      // Add tag with attributes

      if (options.html){
        attr = (_ref5 = _attributesFromObject(attributes)) != null ? _ref5 : '';
        space = attr === '' ? '' : ' ';
        options.html.push("<" + tag + space + attr + ">");
        // Recurse through children if this tag isn't ignored deeply

      }
    }
    if (options.ignore[tag] !== 'deep'){
      for (_k = 0, _len2 = children.length; _k < _len2; _k++){
        child = children[_k];
        // Skip indention if there is only one child

        if (!options.minify && children.length > 1){
          if ((_ref6 = options.html) != null){
            _ref6.push("\n\t" + options.indent);
          }
        }
        _compileDeeper(_compileAny, child, options);
      }
    }
    // Skip indention if there is only one child

    if ((!options.minify) && children.length > 1){
      if ((_ref7 = options.html) != null){
        _ref7.push("\n" + options.indent);
      }
    }
    // End html tag if you have children or your tag closes

    if (!options.ignore[tag]){
      // Close tag if html

      if (options.html && (children.length > 0 || oj.tag.isClosed(tag))){
        if ((_ref8 = options.html) != null){
          _ref8.push("</" + tag + ">");
        }
      }
      // Pop ourselves if dom

      if (options.dom){
        options.dom = options.dom.parentNode;
      }
    }
  };

  // _attributesProcessedForOJ: Process attributes to make them easier to use


  _attributesProcessedForOJ = function(attr){
    var events, jqEvents, k, v;

    jqEvents = {bind:1, on:1, off:1, live:1, blur:1, change:1, click:1, dblclick:1, focus:1, focusin:1, focusout:1, hover:1, keydown:1, keypress:1, keyup:1, mousedown:1, mouseenter:1, mouseleave:1, mousemove:1, mouseout:1, mouseup:1, ready:1, resize:1, scroll:1, select:1};
    // Allow attributes to alias c to class and use arrays instead of space seperated strings

    // Convert to c and class from arrays to strings

    if (oj.isArray(attr != null ? attr.c : void 0)){
      attr.c = attr.c.join(' ');
    }
    if (oj.isArray(attr != null ? attr["class"] : void 0)){
      attr["class"] = attr["class"].join(' ');
    }
    // Move c to class

    if ((attr != null ? attr.c : void 0) != null){
      if ((attr != null ? attr["class"] : void 0) != null){
        attr["class"] += ' ' + attr.c;
      } else {
        attr["class"] = attr.c;
      }
      delete attr.c;
    }
    // Allow attributes to take style as an object

    if (oj.isPlainObject(attr != null ? attr.style : void 0)){
      attr.style = _styleFromObject(attr.style, {
        inline: true
      });
    }
    // Omit attributes with values of false, null, or undefined

    if (oj.isPlainObject(attr)){
      for (k in attr){
        v = attr[k];
        if (v === null || v === void 0 || v === false){
          delete attr[k];
        }
      }
    }
    // Filter out jquery events

    events = {};
    if (oj.isPlainObject(attr)){
      // Filter out attributes that are jquery events

      for (k in attr){
        v = attr[k];
        // If this attribute (k) is an event

        if (jqEvents[k] != null){
          events[k] = v;
          delete attr[k];
        }
      }
    }
    // Returns bindable events

    return events;
  };

  // Bind events to dom


  _attributesBindEventsToDOM = function(events, el){
    var ek, ev, _results;

    _results = [];
    for (ek in events){
      ev = events[ek];
      _a(oj.$ != null, "oj: jquery is missing when binding a '" + ek + "' event");
      if (oj.isArray(ev)){
        _results.push(oj.$(el)[ek].apply(this, ev));
      } else {
        _results.push(oj.$(el)[ek](ev));
      }
    }
    return _results;
  };

  // oj.toHTML


  // ---


  // Make ojml directly to HTML ignoring event bindings and css.


  oj.toHTML = function(options, ojml){
    // Options is optional
    if (!oj.isPlainObject(options)){
      ojml = options;
      options = {};
    }
    // Create html only

    _extend(options, {
      dom: 0,
      js: 0,
      html: 1,
      css: 0
    });
    return (oj.compile(options, ojml)).html;
  };

  // oj.toCSS


  // ---


  // Compile ojml directly to css ignoring event bindings and html.


  oj.toCSS = function(options, ojml){
    // Options is optional
    if (!oj.isPlain(options)){
      ojml = options;
      options = {};
    }
    // Create css only

    _extend(options, {
      dom: 0,
      js: 0,
      html: 0,
      css: 1
    });
    return (oj.compile(options, ojml)).css;
  };

  // _inherit


  // ---


  // Based on, but sadly incompatable with, coffeescript inheritance


  _inherit = function(child, parent){
    // Copy class properties and methods

    var ctor, key;

    for (key in parent){
      oj.copyProperty(child, parent, key);
    }
    ctor = function(){};
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    // Provide easy access for base class methods

    // Example: Parent.base.methodName(arguments...)

    child.base = parent.prototype;
  };

  // _construct(Type, arg1, arg2, ...)


  // ---


  // Construct with specified arguments. This is only necessary because new doesn't support apply/call directly.


  _construct = function(Type){
    return new (FunP.bind.apply(Type, arguments));
  };

  // oj.argumentShift


  // ---


  // Helper to make argument handling easier


  oj.argumentShift = function(args, key){
    var value;

    if ((oj.isPlainObject(args)) && (key != null) && (args[key] != null)){
      value = args[key];
      delete args[key];
    }
    return value;
  };

  // oj.createType


  // ---


  oj.createType = function(name, args){
    var Out, delay, methodKeys, methods, propKeys, properties, typeProps, _ref2, _ref3;

    if (args == null){
      args = {};
    }
    _v('createType', 1, name, 'string');
    _v('createType', 2, args, 'object');
    if ((_ref2 = args.methods) == null){
      args.methods = {};
    }
    if ((_ref3 = args.properties) == null){
      args.properties = {};
    }
    // When auto newing you need to delay construct the properties

    // or they will be constructed twice.

    delay = '__DELAYED__';
    Out = new Function("return function " + name + "(){\n  var _this = this;\n  if ( !(this instanceof " + name + ") ){\n    _this = new " + name + "('" + delay + "');\n    _this.__autonew__ = true;\n  }\n\n  if (arguments && arguments[0] != '" + delay + "')\n    " + name + ".prototype.constructor.apply(_this, arguments);\n\n  return _this;\n}")();
    // Default the constructor to call its base

    if ((args.base != null) && ((args.constructor == null) || (!args.hasOwnProperty('constructor')))){
      args.constructor = function(){
        var _ref4;

        return (_ref4 = Out.base) != null ? _ref4.constructor.apply(this, arguments) : void 0;
      };
    }
    // Inherit if necessary

    if (args.base != null){
      _inherit(Out, args.base);
    }
    // Add the constructor as a method

    oj.addMethod(Out.prototype, 'constructor', args.constructor);
    // Mark new type and its instances with a non-enumerable type and isOJ properties

    typeProps = {
      type: {
        value: Out,
        writable: false,
        enumerable: false
      },
      typeName: {
        value: name,
        writable: false,
        enumerable: false
      },
      isOJ: {
        value: true,
        writable: false,
        enumerable: false
      }
    };
    oj.addProperties(Out, typeProps);
    oj.addProperties(Out.prototype, typeProps);
    // Add properties helper to instance

    propKeys = (_keys(args.properties)).sort();
    if (Out.prototype.properties != null){
      propKeys = _uniqueSort(Out.prototype.properties.concat(propKeys));
    }
    properties = {
      value: propKeys,
      writable: false,
      enumerable: false
    };
    oj.addProperty(Out.prototype, 'properties', properties);
    // Add methods helper to instance

    methodKeys = (_keys(args.methods)).sort();
    if (Out.prototype.methods != null){
      methodKeys = _uniqueSort(Out.prototype.methods.concat(methodKeys));
    }
    methods = {
      value: methodKeys,
      writable: false,
      enumerable: false
    };
    oj.addProperty(Out.prototype, 'methods', methods);
    // Add methods to the type

    _extend(args.methods, {
      // get: Get all properties, or get a single property

      get: function(k){
        var out, p, _j, _len1, _ref4;

        if (oj.isString(k)){
          if (this.has(k)){
            return this[k];
          } else {
            return void 0;
          }
        } else {
          out = {};
          _ref4 = this.properties;
          for (_j = 0, _len1 = _ref4.length; _j < _len1; _j++){
            p = _ref4[_j];
            out[p] = this[p];
          }
          return out;
        }
      },
      // set: Set all properties on the object at once

      set: function(k, v){
        var key, obj, value;

        obj = k;
        // Optionally take key, value instead of object

        if (!oj.isPlainObject(k)){
          obj = {};
          obj[k] = v;
        }
        // Set all keys that are valid properties

        for (key in obj){
          value = obj[key];
          if (this.has(key)){
            this[key] = value;
          }
        }
      },
      // has: Determine if property exists

      has: function(k){
        return this.properties.some(function(v){
          return v === k;
        });
      },
      // can: Determine if method exists

      can: function(k){
        return this.methods.some(function(v){
          return v === k;
        });
      },
      // toJSON: Use properties to generate json

      toJSON: function(){
        var json, prop, _j, _len1, _ref4;

        json = {};
        _ref4 = this.properties;
        for (_j = 0, _len1 = _ref4.length; _j < _len1; _j++){
          prop = _ref4[_j];
          json[prop] = this[prop];
        }
        return json;
      }
    });
    // Add methods

    oj.addMethods(Out.prototype, args.methods);
    // Add the properties

    oj.addProperties(Out.prototype, args.properties);
    return Out;
  };

  // unionArguments:


  // Take arguments and tranform them into options and args.


  // options is a union of all items in `arguments` that are objects


  // args is a concat of all arguments that aren't objects in the same order


  oj.unionArguments = function(argList){
    var args, options, v, _j, _len1;

    options = {};
    args = [];
    for (_j = 0, _len1 = argList.length; _j < _len1; _j++){
      v = argList[_j];
      if (oj.isPlainObject(v)){
        options = _extend(options, v);
      } else {
        args.push(v);
      }
    }
    return {
      options: options,
      args: args
    };
  };

  // _createQuietType


  // ---


  _createQuietType = function(typeName){
    return oj[_getQuietTagName(typeName)] = function(){
      return _construct.apply(null, [oj[typeName]].concat(__slice.call(arguments), [{
        __quiet__: 1
      }]));
    };
  };

  // oj.createEnum


  // ---


  oj.createEnum = function(name, args){
    return _a(0, 'NYI', 'createEnum');
  };

  // oj.View


  // ---


  oj.View = oj.createType('View', {
    // Views are special objects map properties together. This is a union of arguments

    // With the remaining arguments becoming a list

    constructor: function(){
      var args, options, _ref2;

      _a(oj.isDOM(this.el), 'constructor failed to set this.el', this.typeName);
      // Set instance on @el

      _setInstanceOnElement(this.el, this);
      _ref2 = oj.unionArguments(arguments), options = _ref2.options, args = _ref2.args;
      // Emit as a tag if new wasn't called or quiet is not set

      if (this.__autonew__ && !options.__quiet__){
        this.emit();
      }
      // Remove quiet flag

      if (options.__quiet__ != null){
        delete options.__quiet__;
      }
      // Add class oj-typeName

      this.$el.addClass("oj-" + this.typeName);
      // Views automatically set all options to their properties

      // arguments directly to properties

      this.set(options);
      // Remove options that were set

      options = _clone(options);
      this.properties.forEach(function(v){
        return delete options[v];
      });
      // Views pass through remaining options to be attributes on the root element

      // This can include jquery events and interpreted arguments

      this.addAttributes(options);
      // Record if view is fully constructed

      return this._isConstructed = true;
    },
    properties: {
      // The element backing the View

      el: {
        get: function(){
          return this._el;
        },
        set: function(v){
          // Set the element directly if this is a dom element
          if (oj.isDOMElement(v)){
            this._el = v;
            // Clear cache of $el

            this._$el = null;
          } else {
            // Generate the element from ojml

            this._el = oj.compile({
              css: 0,
              cssMap: 0,
              dom: 1,
              html: 0
            }, v).dom;
          }
        }
      },
      // Get and cache jquery-enabled element (readonly)

      $el: {
        get: function(){
          var _ref2;

          return (_ref2 = this._$el) != null ? _ref2 : (this._$el = oj.$(this.el));
        }
      },
      // Get and set id attribute of view

      id: {
        get: function(){
          return this.$el.attr('id');
        },
        set: function(v){
          return this.$el.attr('id', v);
        }
      },
      // class:

      // get: -> @$el.attr 'class'

      // set: (v) ->

      //   # Join arrays with spaces

      //   if oj.isArray v

      //     v = v.join ' '

      //   @$el.attr 'class', v

      //   return

      // Alias for classes

      // c:

      // get: -> @class

      // set: (v) -> @class = v; return

      // Get all currently set attributes (readonly)

      attributes: {
        get: function(){
          var out;

          out = {};
          slice.call(this.el.attributes).forEach(function(attr){
            return out[attr.name] = attr.value;
          });
          return out;
        }
      },
      // Get all classes as an array (readwrite)

      classes: {
        get: function(){
          return this.$el.attr('class').split(/\s+/);
        },
        set: function(v){
          this.$el.attr('class', v.join(' '));
        }
      },
      // Get / set all currently set themes (readwrite)

      themes: {
        get: function(){
          var cls, prefix, thms, _j, _len1, _ref2;

          thms = [];
          prefix = 'theme-';
          _ref2 = this.classes;
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++){
            cls = _ref2[_j];
            if (cls.indexOf(prefix) === 0){
              thms.push(cls.slice(prefix.length));
            }
          }
          return thms;
        },
        set: function(v){
          var theme, _j, _len1;

          if (!oj.isArray(v)){
            v = [v];
          }
          this.clearThemes();
          for (_j = 0, _len1 = v.length; _j < _len1; _j++){
            theme = v[_j];
            this.addTheme(theme);
          }
        }
      },
      theme: {
        get: function(){
          return this.themes;
        },
        set: function(v){
          this.themes = v;
        }
      },
      // Determine if this view has been fully constructed (readonly)

      isConstructed: {
        get: function(){
          var _ref2;

          return (_ref2 = this._isConstructed) != null ? _ref2 : false;
        }
      },
      // Determine if this view has been fully inserted (readonly)

      isInserted: {
        get: function(){
          var _ref2;

          return (_ref2 = this._isInserted) != null ? _ref2 : false;
        }
      }
    },
    methods: {
      // Mirror backbone view's find by selector

      $: function(){
        var _ref2;

        return (_ref2 = this.$el).find.apply(_ref2, arguments);
      },
      // Add a single attribute

      addAttribute: function(name, value){
        var attr;

        attr = {};
        attr[name] = value;
        this.addAttributes(attr);
      },
      // Add attributes and apply the oj magic with jquery binding

      addAttributes: function(attributes){
        var att, attr, events, k, v;

        attr = _clone(attributes);
        events = _attributesProcessedForOJ(attr);
        // Add attributes as object

        if (oj.isPlainObject(attr)){
          for (k in attr){
            v = attr[k];
            if (k === 'class'){
              this.addClass(v);
            } else if (v === true){
              // Boolean attributes have no value

              att = document.createAttribute(k);
              this.el.setAttributeNode(att);
            } else {
              // Otherwise add it normally

              this.$el.attr(k, v);
            }
          }
        }
        // Bind events

        if (events != null){
          _attributesBindEventsToDOM(events, this.el);
        }
      },
      // Remove a single attribute

      removeAttribute: function(name){
        this.$el.removeAttr(name);
      },
      // Remove multiple attributes

      removeAttributes: function(list){
        var k, _j, _len1;

        for (_j = 0, _len1 = list.length; _j < _len1; _j++){
          k = list[_j];
          this.removeAttribute(k);
        }
      },
      // Add a single class

      addClass: function(name){
        this.$el.addClass(name);
      },
      // Remove a single class

      removeClass: function(name){
        this.$el.removeClass(name);
      },
      // Determine if class is applied

      hasClass: function(name){
        return this.$el.hasClass(name);
      },
      // Add a single theme

      addTheme: function(name){
        this.addClass("theme-" + name);
      },
      // Remove a single theme

      removeTheme: function(name){
        this.removeClass("theme-" + name);
      },
      // Determine if theme is applied

      hasTheme: function(name){
        return this.hasClass("theme-" + name);
      },
      // Clear all themes

      clearThemes: function(){
        var theme, _j, _len1, _ref2;

        _ref2 = this.themes;
        for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++){
          theme = _ref2[_j];
          this.removeTheme(theme);
        }
      },
      // emit: Emit instance as a tag function would do

      emit: function(){
        oj._argsAppend(this);
      },
      // Convert View to html

      toHTML: function(options){
        return this.el.outerHTML + ((options != null ? options.minify : void 0) ? '' : '\n');
      },
      // Convert View to dom (for compiling)

      toDOM: function(){
        return this.el;
      },
      // Convert

      toCSS: function(options){
        return _cssFromPluginObject(_flattenCSSMap(this.cssMap), _extend({}, {
          minify: options.minify,
          tags: 0
        }));
      },
      // Convert

      toCSSMap: function(){
        return this.type.cssMap;
      },
      // Convert View to string (for debugging)

      toString: function(){
        return this.toHTML();
      },
      // detach: -> throw 'detach nyi'

      // # The implementation is to set el manipulate it, and remember how to set it back

      // attach: -> throw 'attach nyi'

      // # The implementation is to unset el from detach

      // inserted is called the instance is inserted in the dom (override)

      inserted: function(){
        return this._isInserted = true;
      }
    }
  });

  // oj.View.css: set view's css with css object mapping, or raw css string


  oj.View.css = function(css){
    var cssMap, _base, _base1, _name, _name1, _ref2, _ref3;

    _a(oj.isString(css) || oj.isPlainObject(css), 'object or string expected for first argument', this.typeName);
    if (oj.isString(css)){
      if ((_ref2 = (_base = this.cssMap)[_name = "oj-" + this.typeName]) == null){
        _base[_name] = "";
      }
      this.cssMap["oj-" + this.typeName] += css;
    } else {
      if ((_ref3 = (_base1 = this.cssMap)[_name1 = "oj-" + this.typeName]) == null){
        _base1[_name1] = {};
      }
      cssMap = _setObject({}, ".oj-" + this.typeName, css);
      _extend(this.cssMap["oj-" + this.typeName], cssMap);
    }
  };

  // oj.View.theme: create a View specific theme with css object mapping


  oj.View.theme = function(name, css){
    var cssMap, dashName, _base, _name, _ref2;

    _v(this.typeName, 1, name, 'string');
    _v(this.typeName, 2, css, 'object');
    if ((_ref2 = (_base = this.cssMap)[_name = "oj-" + this.typeName]) == null){
      _base[_name] = {};
    }
    dashName = _dasherize(name);
    cssMap = _setObject({}, ".oj-" + this.typeName + ".theme-" + dashName, css);
    _extend(this.cssMap["oj-" + this.typeName], cssMap);
    this.themes.push(dashName);
    this.themes = _uniqueSort(this.themes);
  };

  oj.View.cssMap = {};

  oj.View.themes = [];

  // oj.CollectionView


  // ---


  oj.CollectionView = oj.createType('CollectionView', {
    base: oj.View,
    constructor: function(options){
      if ((options != null ? options.each : void 0) != null){
        this.each = oj.argumentShift(options, 'each');
      }
      if ((options != null ? options.models : void 0) != null){
        this.models = oj.argumentShift(options, 'models');
      }
      oj.CollectionView.base.constructor.apply(this, arguments);
      // Once everything is constructed call make precisely once.

      return this.make();
    },
    properties: {
      each: {
        get: function(){
          return this._each;
        },
        set: function(v){
          this._each = v;
          if (this.isConstructed){
            this.make();
          }
        }
      },
      collection: {
        get: function(){
          return this.models;
        },
        set: function(v){
          return this.models = v;
        }
      },
      models: {
        get: function(){
          return this._models;
        },
        set: function(v){
          // Unbind events if collection

          var _ref2, _ref3;

          if (oj.isFunction((_ref2 = this._models) != null ? _ref2.off : void 0)){
            this._models.off('add remove change reset destroy', null, this);
          }
          this._models = v;
          // Bind events if collection

          if (oj.isFunction((_ref3 = this._models) != null ? _ref3.on : void 0)){
            this._models.on('add', this.collectionModelAdded, this);
            this._models.on('remove', this.collectionModelRemoved, this);
            this._models.on('change', this.collectionModelChanged, this);
            this._models.on('destroy', this.collectionModelDestroyed, this);
            this._models.on('reset', this.collectionReset, this);
          }
          if (this.isConstructed){
            this.make();
          }
        }
      }
    },
    methods: {
      // Override make to create your view

      make: function(){
        return _a(0, '`make` method not implemented by custom view', this.typeName);
      },
      // Override these events to minimally update on change

      collectionModelAdded: function(model, collection){
        return this.make();
      },
      collectionModelRemoved: function(model, collection, options){
        return this.make();
      },
      collectionModelChanged: function(model, collection, options){},
      collectionModelDestroyed: function(collection, options){
        return this.make();
      },
      collectionReset: function(collection, options){
        return this.make();
      }
    }
  });

  // oj.ModelView


  // ---


  // Model view base class


  oj.ModelView = oj.createType('ModelView', {
    base: oj.View,
    constructor: function(options){
      if ((options != null ? options.value : void 0) != null){
        this.value = oj.argumentShift(options, 'value');
      }
      if ((options != null ? options.model : void 0) != null){
        this.model = oj.argumentShift(options, 'model');
      }
      return oj.ModelView.base.constructor.apply(this, arguments);
    },
    properties: {
      model: {
        get: function(){
          return this._model;
        },
        set: function(v){
          // Unbind events on the old model
          if (oj.isEvented(this._model)){
            this._model.off('change', null, this);
          }
          this._model = v;
          // Bind events on the new model

          if (oj.isEvented(this._model)){
            this._model.on('change', this.modelChanged, this);
          }
          // Trigger change manually when settings new model

          this.modelChanged();
        }
      }
    },
    methods: {
      // Override modelChanged if you don't want a full remake

      modelChanged: function(){
        var _this = this;

        return this.$el.oj(function(){
          return _this.make(_this.mode);
        });
      },
      make: function(model){
        return _a(0, '`make` method not implemented by custom view', this.typeName);
      }
    }
  });

  // oj.ModelKeyView


  // ---


  // Model key view base class


  oj.ModelKeyView = oj.createType('ModelKeyView', {
    // Inherit ModelView to handle model and bindings

    base: oj.ModelView,
    constructor: function(options){
      // console.log "ModelKeyView.constructor: ", JSON.stringify arguments
      if ((options != null ? options.key : void 0) != null){
        this.key = oj.argumentShift(options, 'key');
      }
      // Call super to bind model and value

      return oj.ModelKeyView.base.constructor.apply(this, arguments);
    },
    properties: {
      // Key used to access model

      key: null,
      // Value directly gets and sets to the dom

      // when it changes it must trigger viewChanged

      value: {
        get: function(){
          return _a(0, 'value getter not implemented', this.typeName);
        },
        set: function(v){
          return _a(0, 'value setter not implemented', this.typeName);
        }
      }
    },
    methods: {
      // When the model changes update the value

      modelChanged: function(){
        if ((this.model != null) && (this.key != null)){
          // Update the view if necessary

          if (!this._viewUpdatedModel){
            this.value = this.model.get(this.key);
          }
        }
      },
      // When the view changes update the model

      viewChanged: function(){
        // Delay view changes because many of them hook before controls update

        var _this = this;

        setTimeout((function(){
          if ((_this.model != null) && (_this.key != null)){
            // Ensure view changes aren't triggered twice

            _this._viewUpdatedModel = true;
            _this.model.set(_this.key, _this.value);
            _this._viewUpdatedModel = false;
          }
        }), 10);
      }
    }
  });

  // oj.TextBox


  // ---


  // TextBox control


  oj.TextBox = oj.createType('TextBox', {
    base: oj.ModelKeyView,
    constructor: function(){
      var args, options, _ref2,
        _this = this;

      _ref2 = oj.unionArguments(arguments), options = _ref2.options, args = _ref2.args;
      this.el = oj(function(){
        return oj.input({
          type: 'text'
        }, {
          // Delay change event slighty as value is updated after key presses

          keydown: function(){
            if (_this.live){
              setTimeout((function(){
                return _this.$el.change();
              }), 10);
            }
          },
          keyup: function(){
            if (_this.live){
              setTimeout((function(){
                return _this.$el.change();
              }), 10);
            }
          },
          change: function(){
            _this.viewChanged();
          }
        });
      });
      // Value can be set by argument

      if (args.length > 0){
        this.value = args[0];
      }
      // Set live if it exists

      if ((options != null ? options.live : void 0) != null){
        this.live = oj.argumentShift(options, 'live');
      }
      return oj.TextBox.base.constructor.apply(this, [options]);
    },
    properties: {
      value: {
        get: function(){
          var v;

          v = this.el.value;
          if ((v == null) || v === _undef){
            v = '';
          }
          return v;
        },
        set: function(v){
          this.el.value = v;
        }
      },
      // Live update model as text changes

      live: true
    }
  });

  // oj.CheckBox


  // ---


  // CheckBox control


  oj.CheckBox = oj.createType('CheckBox', {
    base: oj.ModelKeyView,
    constructor: function(){
      var args, options, _ref2,
        _this = this;

      _ref2 = oj.unionArguments(arguments), options = _ref2.options, args = _ref2.args;
      this.el = oj(function(){
        return oj.input({
          type: 'checkbox'
        }, {
          change: function(){
            _this.viewChanged();
          }
        });
      });
      // Value can be set by argument

      if (args.length > 0){
        this.value = args[0];
      }
      return oj.CheckBox.base.constructor.call(this, options);
    },
    properties: {
      value: {
        get: function(){
          return this.el.checked;
        },
        set: function(v){
          v = !!v;
          this.el.checked = v;
          if (v){
            this.$el.attr('checked', 'checked');
          } else {
            this.$el.removeAttr('checked');
          }
        }
      }
    }
  });

  // oj.Text


  // ---


  // Text control


  oj.Text = oj.createType('Text', {
    base: oj.ModelKeyView,
    constructor: function(){
      var args, options, _ref2,
        _this = this;

      _ref2 = oj.unionArguments(arguments), options = _ref2.options, args = _ref2.args;
      // Get tag name if provided

      this._tagName = oj.argumentShift(options, 'tagName');
      this.el = oj(function(){
        return oj[_this.tagName]();
      });
      // Value can be set by argument

      if (args.length > 0){
        this.value = args[0];
      }
      return oj.Text.base.constructor.call(this, options);
    },
    properties: {
      // value: text value of this object (readwrite)

      value: {
        get: function(){
          return this.$el.ojValue();
        },
        set: function(v){
          this.$el.oj(v);
        }
      },
      // tagName: name of root tag (writeonce)

      tagName: {
        get: function(){
          var _ref2;

          return (_ref2 = this._tagName) != null ? _ref2 : 'div';
        }
      }
    }
  });

  // oj.TextArea


  // ---


  // TextArea control


  oj.TextArea = oj.createType('TextArea', {
    base: oj.ModelKeyView,
    constructor: function(){
      var args, options, _ref2,
        _this = this;

      _ref2 = oj.unionArguments(arguments), options = _ref2.options, args = _ref2.args;
      this.el = oj(function(){
        return oj.textarea({
          // Delay change event slighty as value is updated after key presses

          keydown: function(){
            if (_this.live){
              setTimeout((function(){
                return _this.$el.change();
              }), 10);
            }
          },
          keyup: function(){
            if (_this.live){
              setTimeout((function(){
                return _this.$el.change();
              }), 10);
            }
          },
          change: function(){
            _this.viewChanged();
          }
        });
      });
      // Value can be set by argument

      this.value = oj.argumentShift(options, 'value') || args.join('\n');
      return oj.TextArea.base.constructor.call(this, options);
    },
    properties: {
      value: {
        get: function(){
          return this.el.value;
        },
        set: function(v){
          this.el.value = v;
        }
      },
      // Live update model as text changes

      live: true
    }
  });

  // oj.ListBox


  // ---


  // ListBox control


  oj.ListBox = oj.createType('ListBox', {
    base: oj.ModelKeyView,
    constructor: function(){
      var args, options, _ref2,
        _this = this;

      _ref2 = oj.unionArguments(arguments), options = _ref2.options, args = _ref2.args;
      this.el = oj(function(){
        return oj.select({
          change: function(){
            _this.viewChanged();
          }
        });
      });
      // @options is a list of elements

      this.options = oj.argumentShift(options, 'options');
      // Value can be set by argument

      if (args.length > 0){
        this.value = args[0];
      }
      return oj.ListBox.base.constructor.apply(this, [options]);
    },
    properties: {
      value: {
        get: function(){
          return this.$el.val();
        },
        set: function(v){
          this.$el.val(v);
        }
      },
      options: {
        get: function(){
          return this._options;
        },
        set: function(v){
          if (!oj.isArray(v)){
            throw new Error("oj." + this.typeName + ".options array is missing");
          }
          this._options = v;
          this.$el.oj(function(){
            var op, _j, _len1;

            for (_j = 0, _len1 = v.length; _j < _len1; _j++){
              op = v[_j];
              oj.option(op);
            }
          });
        }
      }
    }
  });

  // oj.Button


  // ---


  // Button control


  oj.Button = oj.createType('Button', {
    base: oj.View,
    constructor: function(){
      var args, options, title, _ref2,
        _this = this;

      _ref2 = oj.unionArguments(arguments), options = _ref2.options, args = _ref2.args;
      // Label is first argument

      title = '';
      if (args.length > 0){
        title = args[0];
      }
      // Label is specified as option

      if (options.title != null){
        title = oj.argumentShift(options, 'title');
      }
      this.el = oj(function(){
        return oj.button(title);
      });
      oj.Button.base.constructor.apply(this, [options]);
      return this.title = title;
    },
    properties: {
      title: {
        get: function(){
          var _ref2;

          return (_ref2 = this._title) != null ? _ref2 : '';
        },
        set: function(v){
          this.$el.oj((this._title = v));
        }
      }
    },
    methods: {
      click: function(){
        var _ref2;

        if (arguments.length > 0){
          return (_ref2 = this.$el).click.apply(_ref2, arguments);
        } else {
          return this.$el.click();
        }
      }
    }
  });

  // oj.List


  // ---


  // List control with model bindings and live editing


  oj.List = oj.createType('List', {
    base: oj.CollectionView,
    constructor: function(){
      var args, items, options, _ref2, _ref3,
        _this = this;

      _ref2 = oj.unionArguments(arguments), options = _ref2.options, args = _ref2.args;
      // tagName is write-once

      this._tagName = oj.argumentShift(options, 'tagName');
      this.itemTagName = oj.argumentShift(options, 'itemTagName');
      // Generate el

      this.el = oj(function(){
        return oj[_this.tagName]();
      });
      // Use el if it was passed in

      if (options.el != null){
        this.el = oj.argumentShift(options, 'el');
      }
      // Default @each function to pass through values

      if ((_ref3 = options.each) == null){
        options.each = function(model){
          if ((oj.isString(model)) || (oj.isNumber(model)) || (oj.isBoolean(model))){
            return model;
          } else {
            return JSON.stringify(model);
          }
        };
      }
      // Args have been handled so don't pass them on

      oj.List.base.constructor.apply(this, [options]);
      // Set @items to options or args if they exist

      items = args.length > 0 ? args : null;
      return this.items = options.items != null ? oj.argumentShift(options, 'items') : items;
    },
    // Properties

    properties: {
      // items: get or set all items at once (readwrite)

      items: {
        get: function(){
          // Used cached items or items as interpreted by ojValues jquery plugin

          var v;

          if (this._items != null){
            return this._items;
          }
          return v = this.$items.ojValues();
        },
        set: function(v){
          this._items = v;
          this.make();
        }
      },
      count: {
        get: function(){
          return this.$items.length;
        }
      },
      // tagName: name of root tag (writeonce)

      tagName: {
        get: function(){
          var _ref2;

          return (_ref2 = this._tagName) != null ? _ref2 : 'div';
        }
      },
      // itemTagName: name of item tags (readwrite)

      itemTagName: {
        get: function(){
          var _ref2;

          return (_ref2 = this._itemTagName) != null ? _ref2 : 'div';
        },
        set: function(v){
          this._itemTagName = v;
          this.make();
        }
      },
      // $items: list of `<li>` elements (readonly)

      $items: {
        get: function(){
          var _ref2;

          return (_ref2 = this._$items) != null ? _ref2 : (this._$items = this.$("> " + this.itemTagName));
        }
      }
    },
    // Methods

    methods: {
      //

      // item: get or set item value at item ix

      item: function(ix, ojml){
        ix = this._bound(ix, this.count, ".item: index");
        if (ojml != null){
          this.$item(ix).oj(ojml);
        } else {
          return this.$item(ix).ojValue();
        }
      },
      // $item: `<li>` element for a given item ix. The tag name may change.

      $item: function(ix){
        return this.$items.eq(this._bound(ix, this.count, ".$item: index"));
      },
      // CollectionView Methods

      // make: Remake view from property data

      make: function(){
        // Some properties call make before construction completes

        var model, models, views, _j, _len1,
          _this = this;

        if (!this.isConstructed){
          return;
        }
        // Convert models to views

        views = [];
        if ((this.models != null) && (this.each != null)){
          models = oj.isEvented(this.models) ? this.models.models : this.models;
          for (_j = 0, _len1 = models.length; _j < _len1; _j++){
            model = models[_j];
            views.push(this._itemFromModel(model));
          }
        } else if (this.items != null){
          // Items are already views

          views = this.items;
        }
        // Render the views

        this.$el.oj(function(){
          var view, _k, _len2, _results;

          _results = [];
          for (_k = 0, _len2 = views.length; _k < _len2; _k++){
            view = views[_k];
            _results.push(_this._itemElFromItem(view));
          }
          return _results;
        });
        this.itemsChanged();
        //

        // collectionModelAdded: Model add occurred, add the item

      },
      collectionModelAdded: function(m, c){
        this.add(c.indexOf(m), this._itemFromModel(m));
      },
      // collectionModelRemoved: Model remove occured, delete the item

      collectionModelRemoved: function(m, c, o){
        this.remove(o.index);
      },
      // collectionModelRemoved: On add

      collectionReset: function(){
        this.make();
      },
      // Helper Methods

      // _itemFromModel: Helper to map model to item

      _itemFromModel: function(model){
        var _this = this;

        return oj(function(){
          return _this.each(model);
        });
      },
      // _itemElFromItem: Helper to create itemTagName wrapped item

      _itemElFromItem: function(item){
        return oj[this.itemTagName](item);
      },
      // _bound: Bound index to allow negatives, throw when out of range

      _bound: function(ix, count, message){
        var ixNew;

        ixNew = ix < 0 ? ix + count : ix;
        if (!(0 <= ixNew && ixNew < count)){
          throw new Error("oj." + this.typeName + message + " is out of bounds (" + ix + " in [0," + (count - 1) + "])");
        }
        return ixNew;
      },
      // Events

      // itemsChanged: Model changed occured, clear relevant cached values

      itemsChanged: function(){
        this._items = null;
        this._$items = null;
      },
      // Manipulation Methods

      add: function(ix, ojml){
        // ix defaults to -1 and is optional

        var tag;

        if (ojml == null){
          ojml = ix;
          ix = -1;
        }
        ix = this._bound(ix, this.count + 1, ".add: index");
        tag = this.itemTagName;
        if (this.count === 0){
          // Empty

          this.$el.oj(function(){
            return oj[tag](ojml);
          });
        } else if (ix === this.count){
          // Last

          this.$item(ix - 1).ojAfter(function(){
            return oj[tag](ojml);
          });
        } else {
          // Not last

          this.$item(ix).ojBefore(function(){
            return oj[tag](ojml);
          });
        }
        this.itemsChanged();
      },
      remove: function(ix){
        var out;

        if (ix == null){
          ix = -1;
        }
        ix = this._bound(ix, this.count, ".remove: index");
        out = this.item(ix);
        this.$item(ix).remove();
        this.itemsChanged();
        return out;
      },
      move: function(ixFrom, ixTo){
        if (ixTo == null){
          ixTo = -1;
        }
        if (ixFrom === ixTo){
          return;
        }
        ixFrom = this._bound(ixFrom, this.count, ".move: fromIndex");
        ixTo = this._bound(ixTo, this.count, ".move: toIndex");
        if (ixTo > ixFrom){
          this.$item(ixFrom).insertAfter(this.$item(ixTo));
        } else {
          this.$item(ixFrom).insertBefore(this.$item(ixTo));
        }
        this.itemsChanged();
      },
      swap: function(ix1, ix2){
        var ixMax, ixMin;

        if (ix1 === ix2){
          return;
        }
        ix1 = this._bound(ix1, this.count, ".swap: firstIndex");
        ix2 = this._bound(ix2, this.count, ".swap: secondIndex");
        if (Math.abs(ix1 - ix2) === 1){
          this.move(ix1, ix2);
        } else {
          ixMin = Math.min(ix1, ix2);
          ixMax = Math.max(ix1, ix2);
          this.move(ixMax, ixMin);
          this.move(ixMin + 1, ixMax);
        }
        this.itemsChanged();
      },
      unshift: function(v){
        this.add(0, v);
      },
      shift: function(){
        return this.remove(0);
      },
      push: function(v){
        this.add(this.count, v);
      },
      pop: function(){
        return this.remove(-1);
      },
      clear: function(){
        this.$items.remove();
        this.itemsChanged();
      }
    }
  });

  // oj.NumberList


  // ---


  // NumberList is a `List` specialized with `<ol>` and `<li>` tags


  oj.NumberList = oj.createType('NumberList', {
    base: oj.List,
    constructor: function(){
      var args;

      args = [{
          tagName: 'ol',
          itemTagName: 'li'
        }].concat(__slice.call(arguments));
      return oj.NumberList.base.constructor.apply(this, args);
    }
  });

  // oj.BulletList


  // ---


  // BulletList is a `List` specialized with `<ul>` and `<li>` tags


  oj.BulletList = oj.createType('BulletList', {
    base: oj.List,
    constructor: function(){
      var args;

      args = [{
          tagName: 'ul',
          itemTagName: 'li'
        }].concat(__slice.call(arguments));
      return oj.BulletList.base.constructor.apply(this, args);
    }
  });

  // oj.Table


  // ---


  // Table control


  oj.Table = oj.createType('Table', {
    // Inherit and construct

    base: oj.CollectionView,
    constructor: function(){
      // console.log "Table constructor: ", arguments

      var arg, args, options, rows, _j, _len1, _ref2, _ref3, _ref4,
        _this = this;

      _ref2 = oj.unionArguments(arguments), options = _ref2.options, args = _ref2.args;
      // Generate el

      this.el = oj(function(){
        return oj.table();
      });
      // Use el if it was passed in

      if (options.el != null){
        this.el = oj.argumentShift(options, 'el');
      }
      // Default @each function to pass through values

      if ((_ref3 = options.each) == null){
        options.each = function(model, cell){
          var v, values, _j, _len1, _results;

          values = (oj.isString(model)) || (oj.isNumber(model)) || (oj.isBoolean(model)) ? [model] : (oj.isEvented(model)) && typeof model.attributes === 'object' ? _values(model.attributes) : _values(model);
          _results = [];
          for (_j = 0, _len1 = values.length; _j < _len1; _j++){
            v = values[_j];
            _results.push(cell(v));
          }
          return _results;
        };
      }
      // Args have been handled so don't pass them on

      oj.Table.base.constructor.apply(this, [options]);
      // Validate args as arrays

      for (_j = 0, _len1 = args.length; _j < _len1; _j++){
        arg = args[_j];
        if (!oj.isArray(arg)){
          throw new Error('oj.Table: array expected for row arguments');
        }
      }
      // Set @rows to options or args if they exist

      rows = (_ref4 = oj.argumentShift(options, 'rows')) != null ? _ref4 : args;
      if (rows.length > 0){
        return this.rows = rows;
      }
    },
    properties: {
      // rowCount: The number of rows (readonly)

      rowCount: {
        get: function(){
          return this.$trs.length;
        }
      },
      // columnCount: The number of columns (readonly)

      columnCount: {
        get: function(){
          var tflen, thlen, trlen;

          if ((trlen = this.$tr(0).find('> td').length) > 0){
            return trlen;
          } else if ((thlen = this.$theadTR.find('> th').length) > 0){
            return thlen;
          } else if ((tflen = this.$tfootTR.find('> td').length) > 0){
            return tflen;
          } else {
            return 0;
          }
        }
      },
      //

      // rows: Row values as a list of lists as interpreted by ojValue plugin (readwrite)

      rows: {
        get: function(){
          var r, rx, _j, _ref2;

          if (this._rows != null){
            return this._rows;
          }
          this._rows = [];
          for (rx = _j = 0, _ref2 = this.rowCount; _j < _ref2; rx = _j += 1){
            r = this.$tdsRow(rx).toArray().map(function(el){
              return $(el).ojValue();
            });
            this._rows.push(r);
          }
          return this._rows;
        },
        set: function(list){
          if (!((list != null) && list.length > 0)){
            return this.clearBody();
          }
          this._rows = list;
          this.make();
        }
      },
      // header: Array of header values as interpreted by ojValue plugin (readwrite)

      header: {
        get: function(){
          return this.$theadTR.find('> th').ojValues();
        },
        set: function(list){
          var _this = this;

          if (!oj.isArray(list)){
            throw new Error('oj.Table.header: array expected for first argument');
          }
          if (!((list != null) && list.length > 0)){
            return this.clearHeader();
          }
          return this.$theadTRMake.oj(function(){
            var ojml, _j, _len1, _results;

            _results = [];
            for (_j = 0, _len1 = list.length; _j < _len1; _j++){
              ojml = list[_j];
              _results.push(oj.th(ojml));
            }
            return _results;
          });
        }
      },
      // footer: Array of footer values as interpreted by ojValue plugin (readwrite)

      footer: {
        get: function(){
          return this.$tfootTR.find('> td').ojValues();
        },
        set: function(list){
          var _this = this;

          if (!oj.isArray(list)){
            throw new Error('oj.Table.footer: array expected for first argument');
          }
          if (!((list != null) && list.length > 0)){
            return this.clearFooter();
          }
          return this.$tfootTRMake.oj(function(){
            var ojml, _j, _len1, _results;

            _results = [];
            for (_j = 0, _len1 = list.length; _j < _len1; _j++){
              ojml = list[_j];
              _results.push(oj.td(ojml));
            }
            return _results;
          });
        }
      },
      // caption: The table caption (readwrite)

      caption: {
        get: function(){
          return this.$caption.ojValue();
        },
        set: function(v){
          this.$captionMake.oj(v);
        }
      },
      // Element accessors

      $table: {
        get: function(){
          return this.$el;
        }
      },
      $caption: {
        get: function(){
          return this.$('> caption');
        }
      },
      $colgroup: {
        get: function(){
          return this.$('> colgroup');
        }
      },
      $thead: {
        get: function(){
          return this.$('> thead');
        }
      },
      $tfoot: {
        get: function(){
          return this.$('> tfoot');
        }
      },
      $tbody: {
        get: function(){
          return this.$('> tbody');
        }
      },
      $theadTR: {
        get: function(){
          return this.$thead.find('> tr');
        }
      },
      $tfootTR: {
        get: function(){
          return this.$tfoot.find('> tr');
        }
      },
      $ths: {
        get: function(){
          return this.$theadTR.find('> th');
        }
      },
      $trs: {
        get: function(){
          var _ref2;

          return (_ref2 = this._$trs) != null ? _ref2 : (this._$trs = this.$("> tbody > tr"));
        }
      },
      // Table tags must have an order: `<caption>` `<colgroup>` `<thead>` `<tfoot>` `<tbody>`

      // These accessors create table tags and preserve this order very carefully

      // $colgroupMake: get or create `<colgroup>` after `<caption>` or prepended to `<table>`

      $colgroupMake: {
        get: function(){
          if (this.$colgroup.length > 0){
            return this.$colgroup;
          }
          t = '<colgroup></colgroup>';
          if (this.$caption.length > 0){
            this.$caption.insertAfter(t);
          } else {
            this.$table.append(t);
          }
          return this.$tbody;
        }
      },
      // $captionMake: get or create `<caption>` prepended to `<table>`

      $captionMake: {
        get: function(){
          if (this.$caption.length > 0){
            return this.$caption;
          }
          this.$table.prepend('<caption></caption>');
          return this.$caption;
        }
      },
      // $tfootMake: get or create `<tfoot>` before `<tbody>` or appended to `<table>`

      $tfootMake: {
        get: function(){
          if (this.$tfoot.length > 0){
            return this.$tfoot;
          }
          t = '<tfoot></tfoot>';
          if (this.$tfoot.length > 0){
            this.$tfoot.insertBefore(t);
          } else {
            this.$table.append(t);
          }
          return this.$tfoot;
        }
      },
      // $theadMake: get or create `<thead>` after `<colgroup>` or after `<caption>`, or prepended to `<table>`

      $theadMake: {
        get: function(){
          if (this.$thead.length > 0){
            return this.$thead;
          }
          t = '<thead></thead>';
          if (this.$colgroup.length > 0){
            this.$colgroup.insertAfter(t);
          } else if (this.$caption.length > 0){
            this.$caption.insertAfter(t);
          } else {
            this.$table.prepend(t);
          }
          return this.$thead;
        }
      },
      // $tbodyMake: get or create `<tbody>` appened to `<table>`

      $tbodyMake: {
        get: function(){
          if (this.$tbody.length > 0){
            return this.$tbody;
          }
          this.$table.append('<tbody></tbody>');
          return this.$tbody;
        }
      },
      // $theadTRMake: get or create `<tr>` inside of `<thead>`

      $theadTRMake: {
        get: function(){
          if (this.$theadTR.length > 0){
            return this.$theadTR;
          }
          this.$theadMake.html('<tr></tr>');
          return this.$theadTR;
        }
      },
      // $tfootTRMake: get or create `<tr>` inside of `<tfoot>`

      $tfootTRMake: {
        get: function(){
          if (this.$tfootTR.length > 0){
            return this.$tfootTR;
          }
          this.$tfootMake.html('<tr></tr>');
          return this.$tfootTR;
        }
      }
    },
    // CollectionView Methods

    methods: {
      // make: Remake everything

      make: function(){
        // Some properties call make before construction completes

        var model, models, row, rowViews, _j, _k, _len1, _len2, _ref2,
          _this = this;

        if (!this.isConstructed){
          return;
        }
        // Convert models to views

        rowViews = [];
        if ((this.models != null) && (this.each != null)){
          models = oj.isEvented(this.models) ? this.models.models : this._models;
          for (_j = 0, _len1 = models.length; _j < _len1; _j++){
            model = models[_j];
            rowViews.push(this._rowFromModel(model));
          }
        } else if (this.rows != null){
          // Rows need tds to become views

          _ref2 = this.rows;
          for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++){
            row = _ref2[_k];
            rowViews.push(oj(function(){
              var c, _l, _len3, _results;

              _results = [];
              for (_l = 0, _len3 = row.length; _l < _len3; _l++){
                c = row[_l];
                _results.push(oj.td(c));
              }
              return _results;
            }));
          }
        }
        // Render rows into tbody

        if (rowViews.length > 0){
          this.$tbodyMake.oj(function(){
            var r, _l, _len3, _results;

            _results = [];
            for (_l = 0, _len3 = rowViews.length; _l < _len3; _l++){
              r = rowViews[_l];
              _results.push(oj.tr(r));
            }
            return _results;
          });
        }
        this.bodyChanged();
      },
      //

      // On add minimally create the missing model

      collectionModelAdded: function(m, c){
        var row, rx;

        rx = c.indexOf(m);
        row = this._rowFromModel(m);
        this._addRowTR(rx, oj(function(){
          return oj.tr(row);
        }));
      },
      // On add minimally create the missing model

      collectionModelRemoved: function(m, c, o){
        this.removeRow(o.index);
      },
      collectionReset: function(){
        this.make();
      },
      //

      // table.header(r,ojml)    // value for header

      // table.cell(r,c,ojml)    // get/set value for cell

      // $tr: Get `<tr>` jquery element at row rx

      $tr: function(rx){
        rx = rx < 0 ? rx + count : rx;
        return this.$trs.eq(rx);
      },
      // $tdsRow: Get list of `<td>`s in row rx

      $tdsRow: function(rx){
        rx = rx < 0 ? rx + count : rx;
        return this.$tr(rx).find('> td');
      },
      // $td: Get `<td>` row rx, column cx

      $td: function(rx, cx){
        rx = rx < 0 ? rx + this.rowCount : rx;
        cx = cx < 0 ? cx + this.columnCount : cx;
        return this.$tdsRow(rx).eq(cx);
      },
      // row: Get values at a given row

      row: function(rx, listOJML){
        var cx, ojml, _j, _len1;

        rx = this._bound(rx, this.rowCount, ".row: rx");
        if (listOJML != null){
          if (listOJML.length !== cellCount(rx)){
            throw new Error("oj." + this.typeName + ": array expected for second argument with length length cellCount(" + rx + ")");
          }
          for (cx = _j = 0, _len1 = listOJML.length; _j < _len1; cx = ++_j){
            ojml = listOJML[cx];
            this.$td(rx, cx).oj(ojml);
          }
        } else {
          return this.$tdsRow(rx).ojValues();
        }
      },
      // cell: Get or set value at row rx, column cx

      cell: function(rx, cx, ojml){
        if (ojml != null){
          return this.$td(rx, cx).oj(ojml);
        } else {
          return this.$td(rx, cx).ojValue();
        }
      },
      // Manipulation Methods

      // addRow: Add row to index rx

      addRow: function(rx, listOJML){
        var tr;

        if (listOJML == null){
          listOJML = rx;
          rx = -1;
        }
        rx = this._bound(rx, this.rowCount + 1, ".addRow: rx");
        if (!oj.isArray(listOJML)){
          throw new Error('oj.addRow: expected array for row content');
        }
        tr = function(){
          return oj.tr(function(){
            var o, _j, _len1, _results;

            _results = [];
            for (_j = 0, _len1 = listOJML.length; _j < _len1; _j++){
              o = listOJML[_j];
              _results.push(oj.td(o));
            }
            return _results;
          });
        };
        this._addRowTR(rx, tr);
      },

      // _addRowTR: Helper to add row directly with `<tr>`
      _addRowTR: function(rx, tr){
        // Empty
        if (this.rowCount === 0)
          this.$el.oj(tr)

        // Last
        else if (rx === this.rowCount)
          this.$tr(rx - 1).ojAfter(tr)

        // Not last
        else
          this.$tr(rx).ojBefore(tr)

        this.bodyChanged()
      },

      // removeRow: Remove row at index rx (defaults to end)
      removeRow: function(rx){
        if (rx == null)
          rx = -1
        rx = this._bound(rx, this.rowCount, ".removeRow: index");
        var out = this.row(rx)
        this.$tr(rx).remove()
        this.bodyChanged()
        return out
      },

      // moveRow: Move row at index rx (defaults to end)
      moveRow: function(rxFrom, rxTo){
        if (rxFrom === rxTo)
          return;

        rxFrom = this._bound(rxFrom, this.rowCount, ".moveRow: fromIndex");
        rxTo = this._bound(rxTo, this.rowCount, ".moveRow: toIndex");
        var insert = rxTo > rxFrom ? 'insertAfter' : 'insertBefore';
        this.$tr(rxFrom)[insert](this.$tr(rxTo));
        this.bodyChanged();
      },

      // swapRow: Swap row rx1 and rx2
      swapRow: function(rx1, rx2){
        if (rx1 === rx2)
          return
        rx1 = this._bound(rx1, this.rowCount, ".swap: firstIndex");
        rx2 = this._bound(rx2, this.rowCount, ".swap: secondIndex");
        if (Math.abs(rx1 - rx2) === 1)
          this.moveRow(rx1, rx2)
        else {
          var rxMin = Math.min(rx1, rx2),
            rxMax = Math.max(rx1, rx2)
          this.moveRow(rxMax, rxMin);
          this.moveRow(rxMin + 1, rxMax);
        }
        this.bodyChanged();
      },
      unshiftRow: function(v){this.addRow(0, v)},
      shiftRow: function(){return this.removeRow(0)},
      pushRow: function(v){this.addRow(this.rowCount, v)},
      popRow: function(){return this.removeRow(-1)},
      clearColgroup: function(){this.$colgroup.remove()},
      clearBody: function(){
        this.$tbody.remove();
        this.bodyChanged();
      },
      clearHeader: function(){
        this.$thead.remove();
        this.headerChanged();
      },
      clearFooter: function(){
        this.$tfoot.remove();
        this.footerChanged();
      },
      clearCaption: function(){
        this.$capation.remove();
      },
      clear: function(){
        this.clearBody();
        this.clearHeader();
        this.clearFooter();
        return this.$caption.remove();
      },

      // When body changes clear relevant cached values
      bodyChanged: function(){
        this._rows = null;
        this._columns = null;
        this._$trs = null;
      },

      // When header changes clear relevant cached values
      headerChanged: function(){
        this._header = null;
      },

      // When footer changes clear relevant cached values
      footerChanged: function(){
        this._footer = null;
      },

      // _rowFromModel: Helper to map model to row
      _rowFromModel: function(model){
        var _this = this;

        return oj(function(){
          return _this.each(model, oj.td);
        });
      },

      // _bound: Bound index to allow negatives, throw when out of range
      _bound: function(ix, count, message){
        var ixNew;

        ixNew = ix < 0 ? ix + count : ix;
        if (!(0 <= ixNew && ixNew < count)){
          throw new Error("oj." + this.typeName + message + " is out of bounds (" + ix + " in [0," + (count - 1) + "])");
        }
        return ixNew;
      }
    }
  });

  // Create _Types
  // ---
  // Type with captital first letter that doesn't end in "View"

  for (typeName in oj){
    if (_isCapitalLetter(typeName[0]) && typeName.slice(typeName.length - 4) !== 'View'){
      oj[_getQuietTagName(typeName)] = _createQuietType(typeName);
    }
  }

  // oj.sandbox
  // ---
  // The sandbox is a readonly version of oj that is exposed to the user
  oj.sandbox = {};

  _ref2 = _keys(oj);
  for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++){
    key = _ref2[_j];
    if ((key.length > 0 && key[0] !== '_') || (key.length > 0 && key[0] === '_' && (oj[key.slice(1)] != null))){
      oj.addProperty(oj.sandbox, key, {
        value: oj[key],
        writable: false
      });
    }
  }

  // oj.use(plugin, settings)
  // ---
  // Include a plugin of OJ with `settings`

  oj.use = function(plugin, settings){
    var name, pluginMap, pluginResult, value, _results;

    if (settings == null){
      settings = {};
    }
    _v('use', 1, plugin, 'function');
    _v('use', 2, settings, 'object');

    // Call plugin to gather extension map
    pluginResult = plugin(oj, settings);

    // Add _Type quiet types
    pluginMap = _clone(pluginResult);
    for (name in pluginResult){
      value = pluginResult[name];
      if (oj.isOJType(value)){
        pluginMap[_getQuietTagName(name)] = _createQuietType(value.typeName);
      }
    }

    // Extend all properties
    _results = [];
    for (name in pluginMap){
      value = pluginMap[name];

      // Add to oj
      oj[name] = value;

      // Add to sandbox
      _results.push(oj.addProperty(oj.sandbox, name, {
        value: value,
        writable: false
      }));
    }
    return _results;
  };

  // _jqExtend(fn)
  // ---
  // jQuery Extend
  // option.get is called to retrieve value per element
  // option.set is called when setting elements
  // option.first:true means return only the first get, otherwise it is returned as an array.

  _jqExtend = function(options){
    if (options == null)
      options = {};

    options = _extend({
      get: identity,
      set: identity,
      first: false
    }, options);
    return function(){
      var $els, args, el, out, r, _k, _l, _len2, _len3;

      args = _toArray(arguments);
      $els = jQuery(this);

      // Map over jquery selection if no arguments
      if ((oj.isFunction(options.get)) && args.length === 0){
        out = [];
        for (_k = 0, _len2 = $els.length; _k < _len2; _k++){
          el = $els[_k];
          out.push(options.get(oj.$(el)));
          if (options.first){
            return out[0];
          }
        }
        return out;
      } else if (oj.isFunction(options.set)){

        // By default return this for chaining
        out = $els;
        for (_l = 0, _len3 = $els.length; _l < _len3; _l++){
          el = $els[_l];
          r = options.set(oj.$(el), args);
          // Short circuit if anything is returned

          if (r != null){
            return r;
          }
        }
        return $els;
      }
    };
  };

  _triggerTypes = function(types){
    var type, _k, _len2;

    for (_k = 0, _len2 = types.length; _k < _len2; _k++){
      type = types[_k];
      type.inserted();
    }
  };

  _insertStyles = function(pluginMap, options){
    var mediaMap, plugin;

    for (plugin in pluginMap){
      mediaMap = pluginMap[plugin];

      // Skip global css if options.global is true
      if (plugin === 'oj-style' && !(options != null ? options.global : void 0)){
        continue;
      }

      // Create <style> tag for the plugin
      if (oj.$('.' + _styleClassFromPlugin(plugin)).length === 0){
        oj.$('head').append(oj._styleTagFromMediaObject(plugin, mediaMap));
      }
    }
  };

  // jQuery.fn.oj
  // ---

  oj.$.fn.oj = _jqExtend({
    set: function($el, args){

      var cssMap, d, dom, types, _k, _len2, _ref3;

      // No arguments return the first instance
      if (args.length === 0)
        return $el[0].oj

      // Compile ojml
      _ref3 = oj.compile.apply(oj, [{
        dom: 1,
        html: 0,
        cssMap: 1
      }].concat(__slice.call(args))), dom = _ref3.dom, types = _ref3.types, cssMap = _ref3.cssMap;
      _insertStyles(cssMap, {
        global: 0
      });

      // Reset content and append to dom
      $el.html('');
      if (!oj.isArray(dom)){
        dom = [dom];
      }
      for (_k = 0, _len2 = dom.length; _k < _len2; _k++){
        d = dom[_k];
        $el.append(d);
      }
      _triggerTypes(types);
    },
    get: function($el){
      return $el[0].oj;
    }
  });

  // jQuery.ojBody ojml
  // ---
  // Replace body with ojml. Global css is rebuild when using this method.

  oj.$.ojBody = function(ojml){

    var bodyOnly, cssMap, dom, eCompile, types, _ref3;

    // Compile only the body and below
    bodyOnly = {
      html: 1,
      '!DOCTYPE': 1,
      body: 1,
      head: 'deep',
      meta: 1,
      title: 'deep',
      link: 'deep',
      script: 'deep'
    };
    try {
      _ref3 = oj.compile({
        dom: 1,
        html: 0,
        css: 0,
        cssMap: 1,
        ignore: bodyOnly
      }, ojml), dom = _ref3.dom, types = _ref3.types, cssMap = _ref3.cssMap;
    } catch (_error){
      eCompile = _error;
      throw new Error("oj.compile: " + eCompile.message);
    }

    // Clear body and insert dom elements
    if (dom != null)
      oj.$('body').html(dom);

    _insertStyles(cssMap, {
      global: 1
    });
    return _triggerTypes(types);
  };

  // jQuery.fn.ojValue
  // ---
  // Get the first value of the selected contents

  _jqGetValue = function($el, args){
    var child, el, inst, text;

    el = $el[0];
    child = el.firstChild;
    if (oj.isDOMText(child)){

      // Parse the text to turn it into bool, number, or string
      return text = oj.parse(child.nodeValue);
    } else if (oj.isDOMElement(child)){

      // Get elements as oj instances or elements
      if ((inst = _getInstanceOnElement(child)) != null){
        return inst;
      } else {
        return child;
      }
    }
  };

  oj.$.fn.ojValue = _jqExtend({
    first: true,
    set: null,
    get: _jqGetValue
  });

  // jQuery.fn.ojValues
  // ---
  // Get values as an array of the selected element's contents

  oj.$.fn.ojValues = _jqExtend({
    first: false,
    set: null,
    get: _jqGetValue
  });

  // jQuery plugins
  // ---

  plugins = {
    ojAfter: 'after',
    ojBefore: 'before',
    ojAppend: 'append',
    ojPrepend: 'prepend',
    ojReplaceWith: 'replaceWith',
    ojWrap: 'wrap',
    ojWrapInner: 'wrapInner'
  };

  _fn1 = function(ojName, jqName){
    return oj.$.fn[ojName] = _jqExtend({
      set: function($el, args){

        // Compile ojml for each one to separate references
        var cssMap, dom, types, _ref3;

        _ref3 = oj.compile.apply(oj, [{
          dom: 1,
          html: 0,
          css: 0,
          cssMap: 1
        }].concat(__slice.call(args))), dom = _ref3.dom, types = _ref3.types, cssMap = _ref3.cssMap;
        _insertStyles(cssMap, {
          global: 0
        });

        // Append to the dom
        $el[jqName](dom);
        _triggerTypes(types);
      },
      get: null
    });
  };
  for (ojName in plugins){
    jqName = plugins[ojName];
    _fn1(ojName, jqName);
  }

}).call(this);
