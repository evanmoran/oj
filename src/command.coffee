
vm = require 'vm'
commander = require 'commander'
fs = require 'fs'
coffee = require 'coffee-script'
oj = require './oj'
uglifyjs = require 'uglify-js'
path = require 'path'
_ = oj._

module.exports = ->

  commander.version('0.0.5')
    .usage('[options] <file, ...>')
    .option('-o, --output <dir>', 'Directory to output all files to (default: .)', process.cwd())
    .option('-d, --debug', 'Turn on debug output (default: false)', false)
    .option('-r, --recurse', 'Recurse into directories (default: off)', false)
    .option('-w, --watch <dir,dir,...>', 'Directories to watch (default: off)', trimArgList)
    .option('-v, --verbose', 'Turn on verbose output (default: off)')
    .parse(process.argv)

    # .option('    --css <dir>', 'Directory to output css files to (default: .)')
    # .option('    --js <dir>', 'Directory to output js files to (default: .)')
    # .option('    --html <dir>', 'Directory to output css files to (default: .)')

  # Verify output is a directory
  error "directory expected for --output option (#{commander.output})" unless isDirectory commander.output

  # Verify output specific directories are directories and correctly defaulted
  dirTypeOption = ['--output-css', '--output-js', '--output-html']
  for dirType,ix in ['outputCss', 'outputJs', 'outputHtml']
    # Default specific output directories to the general one if not specified
    if not commander[dirType]
      commander[dirType] = commander.output
    error "directory expected at #{dirTypeOption[ix]} option (#{commander[dirType]})" unless isDirectory commander[dirType]

  # Verify files exist and get full path
  commander.files = commander.args
  error 'expecting one or more files' if not _.isArray(commander.files) or commander.files.length == 0

  # Hooking into require inspired by http://github.com/fgnass/node-dev
  _cacheHooks = {}
  _cacheOrigs = {}
  _hookRequire = ->
    handlers = require.extensions
    for ext of handlers
      # Get or create the hook for the extension
      hook = _cacheHooks[ext] or (_cacheHooks[ext] = _createHook(ext))
      if handlers[ext] != hook
        # Save a reference to the original handler
        _cacheOrigs[ext] = handlers[ext]
        # and replace the handler by our hook
        handlers[ext] = hook

  # Hook into one extension
  _createHook = (ext) ->
    return (module, filename) ->
      # Override compile to intercept file
      if !module.loaded
        # console.log "module: ", module
        _remember filename, null, module.paths

        # if path.extension filename _.indexOf ['.coffee']
        moduleCompile = module._compile
        module._compile = (code) ->
          _remember filename, code, module.paths
          return moduleCompile.apply this, arguments

      # Invoke the original handler
      _cacheOrigs[ext](module, filename)

      # Make sure the module did not hijack the handler
      _hookRequire()


  # Remember require references
  _remembered = {}
  _remember = (filename, code, module) ->
    _remembered[filename] = _.defaults {code: code, module: module}, (_remembered[filename] or {})

  stripBOM = (c) ->
    if c.charCodeAt(0) == 0xFEFF
      c = c.slice 1
    c

  _commonPath = (moduleName, moduleParentPaths) ->
    return null unless moduleName? and _.isArray moduleParentPaths
    for p in moduleParentPaths
      if _.startsWith moduleName, p + '/'
        return p + '/'
    null

  # Hook require to intercept requires in oj files
  _hookRequire()

  crypto = require 'crypto'

  # commander.nativeModules = 'path utils'
  # oj --native path utils --o dir file.oj

  for filePath in commander.files
    require path.join process.cwd(), filePath
  cacheString = _cacheToString _buildCache _remembered

  # console.log "commander.files: ", commander.files
  fs.writeFileSync 'output.js', cacheString

watch = (directories, options = {}) ->
  console.log "watch called: (NYI)"

error = (message, exitCode = 1) ->
  console.log 'oj: ', message
  process.exit exitCode

success = (message) ->
  error message, 0

isFile = (filepath) ->
  try
    (fs.statSync filepath).isFile()
  catch e
    false

isDirectory = (dirpath) ->
  try
    (fs.statSync dirpath).isDirectory()
  catch e
    false

trimArgList = (v) ->
  _.trim v.split(',')

# trim
_.trim = (any) ->
  if _.isString any
    any.trim()
  else if _.isArray any
    out = _.map any, (v) -> v.trim()
    _.reject out, ((v) -> v == '' or v == null)
  else
    any

# startsWith
_.startsWith = (strInput, strStart) ->
  throw 'startsWith: argument error' unless (_.isString strInput) and (_.isString strStart)
  strInput.length >= strStart.length and strInput.lastIndexOf(strStart, 0) == 0

_.escapeSingleQuotes = (str) ->
  str.replace /'/g, "\\'"

minifyJS = (js, options = {}) ->
  uglifyjs js, options

minifyCSS = (css, structureOff = false) ->
  require('csso').justDoIt(css, structureOff)

nodeModulesSupported = assert:1, console:1, crypto:1, events:1, freelist:1, path:1, punycode:1, string_decoder:1, url:1, util:1
nodeModuleUnsupported = fs:1, vm:1, net:1, os:1, tty:1
isNodeModule = (module) -> !!nodeModulesSupported[module]
isUnsupportedNodeModule = (module) -> !!nodeModuleUnsupported[module]
isAppModule = (module) -> (module.indexOf '/') == -1
isRelativeModule = (module) -> (module.indexOf '/') != -1

# The require cache must be cleared so seperate websites can have seperate
_clearRequireCache = ->

# Replace references to `require('<prev>')` with `require('<next>')`
_replaceRequire = (code, prev, next) ->
  # Convert prev to regexp syntax
  prev = prev.replace(/\\/g, '\\\\');   # Backslash backward paths
  prev = prev.replace(/\./g, '\\.');    # Backslash periods

  # Generate regexp to find require with prev
  r = new RegExp "require\\s*\\(\\s*(['\"])" + prev + '\\1\\s*\\)', 'g'

  # Replace references to require with next
  return code.replace r, "require('" + next + "')"

_first = (array, fn) ->
  for x in array
    y = fn x
    return y if y

_getModuleRequires = (code) ->
  r = new RegExp("require\\s*\\(?\\s*[\"']([^\"']+)", 'g');
  out = []
  while match = r.exec code
    out.push match[1]
  out

_replaceRequire = (code, prev, next) ->
  # Convert prev to regexp syntax
  prev = prev.replace(/\\/g, '\\\\');   # Backslash backward paths
  prev = prev.replace(/\./g, '\\.');    # Backslash periods

  # Generate regexp to find require with prev
  r = new RegExp "require\\s*\\(\\s*(['\"])" + prev + '\\1\\s*\\)', 'g'

  # Replace references to require with next
  return code.replace r, "require('" + next + "')"

_first = (array, fn) ->
  for x in array
    y = fn x
    return y if y

# Load all remembered files by reading them if they are missing
_cache = {modules:{}, files:{}}
_buildCache = (remembered) ->

  for filename, data of remembered

    # Read code if it is missing
    if not data.code?
      data.code = stripBOM fs.readFileSync filename, 'utf8'

    # Minify code if necessary
    if not commander.debug
      try
        data.code = minifyJS data.code
      catch e
        console.log "oj.command: could not minify: #{filename}"
        console.log e
        throw e

    # Save code to _fileCache
    _cache.files[filename] = data.code

    pathComponents = _first module.parent.paths, (prefix) ->
      if _.startsWith filename, prefix + path.sep
        modulePath = (filename.slice (prefix.length + 1)).split(path.sep)
        moduleName = modulePath[0]
        moduleMain = modulePath.slice(1).join(path.sep)
        modulesDir: prefix, moduleName:  moduleName, moduleMain: moduleMain, moduleParentPath: module.id

    # Save to _cache.native
    if pathComponents
      if not _cache.modules[pathComponents.modulesDir]
        _cache.modules[pathComponents.modulesDir] = {}
      # Example: /Users/evan/oj/node_modules: {underscore: 'underscore.js'}
      _cache.modules[pathComponents.modulesDir][pathComponents.moduleName] = pathComponents.moduleMain

    # Build _cache.native given source code in _fileCache
    moduleNameList = _getModuleRequires data.code
    for moduleName in moduleNameList
      if isUnsupportedNodeModule moduleName
        throw "oj.command: requiring an unsupported native module (#{moduleName}) in file (#{filename})"
      else if isNodeModule moduleName
        _cache.native[moduleName] = _nativeModuleCode moduleName

  return _cache  # _buildCache

_cacheToString = (cache) ->

  initialFile = path.join process.cwd(), "__index__"

  _fileToString = (filename, code) ->
    filename = _.escapeSingleQuotes filename
    "F['#{filename}'] = (function(require, module){#{code}})(requirer('#{filename}'), module);\n"

  _moduleToString = (moduleDir, moduleName, moduleMain) ->
    moduleDir = _.escapeSingleQuotes moduleDir
    moduleName = _.escapeSingleQuotes moduleName
    moduleMain = _.escapeSingleQuotes moduleMain
    "M['#{moduleDir}'] = {'#{moduleName}': '#{moduleMain}'};\n"

  output = """// oj v#{oj.version}
(function(){
var F = {}, M = {}, N = {};

function resolve(m, f) {
  var dir = path.dirname(f);

  // Relative
  if(!!m.match(/\\//)){
    return path.join(dir, m);
  }

  // Native
  else if (N[m]){
     return N[m];
  }

  // App
  //else {
  //}
}

function requirer(file){
  return function(module){
    r = resolve(module, file);
  };
}\n
"""
  # Save all the module info
  # { '/Users/evan/oj/node_modules': { underscore: 'underscore.js' } }
  for moduleDir, nameToMain of cache.modules
    for moduleName, moduleMain of nameToMain
      output += _moduleToString moduleDir, moduleName, moduleMain

  # Save all the files
  for filename, code of cache.files
    output += _fileToString filename, code

  output += """

window.require = requirer(#{initialFile});
window.oj = require('oj');
}).call(this);
"""

  return output

_nativeModuleCode = (moduleName) ->


