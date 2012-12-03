
# command.coffee
# ====================================================================

vm = require 'vm'
commander = require 'commander'
fs = require 'fs'
coffee = require 'coffee-script'
oj = require './oj'
uglifyjs = require 'uglify-js'
csso = require 'csso'
path = require 'path'
_ = require 'underscore'

module.exports = ->

  commander.version('0.0.5')
    .usage('[options] <file, ...>')
    .option('-d, --debug', 'Turn on debug output (default: false)', false)
    .option('-o, --output <dir>', 'Directory to output all files to (default: .)', process.cwd())
    .option('-r, --recurse', 'Recurse into directories (default: off)', false)
    .option('-v, --verbose <level>', 'Turn on verbose level 0-3 (default: 0)', 0)
    .option('-m, --modules <modules>', 'List of modules to include', [])
    .parse(process.argv)
    # .option('-w, --watch <dir,dir,...>', 'Directories to watch (default: off)', trimArgList)

  # Verify output is a directory
  error "`#{commander.output}` is not a directory" unless isDirectory commander.output

  # Convert args to full paths
  commander.args = fullPaths commander.args, process.cwd()

  # Show usage with no parameters
  if not _.isArray(commander.args) or commander.args.length == 0
    usage()

  # Handle recursion and gather files to compile
  recurseIf commander.recurse, commander.args, (err, files) ->

    # Verify args are actually files
    for f in files
      error "`#{f}` is not a file" if not isFile(f)

    # All verbose
    commander.verbose = 3 if commander.verbose == 'all'

    # Clear underscore as modules might need it
    _clearRequireCacheRecord 'underscore'

    # Compile all files
    compileOptions =
      outputDir: commander.output
      modules: commander.modules or []
      debug: commander.debug or false

    # OJ needs path to implement require
    compileOptions.modules.push 'oj'
    compileOptions.modules.push 'path'

    for file in files
      compile file, compileOptions

# Commands
# =====================================================================

# recurseIf
# --------------------------------------------------------------------
# Abstracts if recursion happened and returns files either recursed or not
# depending on condition

recurseIf = (condition, paths, cb) ->
  if condition
    ls paths, (err, results) ->
      cb null, results.files
  else
    cb null, paths

# compile
# --------------------------------------------------------------------
compile = (filePath, options = {}) ->
  outputDir = options.outputDir || process.cwd()
  fileOut = path.join outputDir, (path.basename filePath, '.oj') + '.html'
  verbose 1, "compiling #{filePath}"

  # Cache of modules, files, and native modules
  cache = modules:{}, files:{}, native:{}

  # Module store for require hook
  modules = {}

  # Hook require to intercept requires in oj files
  _hookRequire modules

  # Save require cache
  _saveRequireCache()

  # Add user defined modules
  for m in options.modules
    if isNodeModule m
      verbose 2, "included #{m}"
      _buildNativeCacheFromModuleList cache.native, [m], options.debug
    else
      require m

  # Require this file to start the process
  ojml = require filePath
  html = (oj.compile debug: options.debug, ojml).html

  # Restore require cache
  _restoreRequireCache()

  # Error if compiled file is missing required tags
  error "<html> tag is missing (#{filePath})" if html.indexOf('<html') == -1
  error "<body> tag is missing (#{filePath})" if html.indexOf('<body') == -1

  # Build cache
  verbose 2, "building #{filePath}"
  cache = _buildRequireCache modules, cache

  # Serialize cache
  verbose 2, "serializing #{filePath}"
  scriptHtml = _requireCacheToString cache

  # Insert script into html just before </body>
  html = _.insertAt html, (html.lastIndexOf '</body>'), scriptHtml

  # Write file
  verbose 1, "saving #{fileOut}"
  fs.writeFileSync fileOut, html

# watch
# --------------------------------------------------------------------

watch = (dir, options = {}) ->
  verbose 1, "watching #{dir}"

# Helpers
# =====================================================================

# Output helpers
# --------------------------------------------------------------------

error = (message, exitCode = 1) ->
  console.log '\n  error:', message, "\n"
  process.exit exitCode

success = ->
  process.exit 0

usage = (code = 0) ->
  commander.help()
  process.exit code

tabs = (count) ->
  Array(count + 1).join('\t')

spaces = (count) ->
  Array(count + 1).join(' ')

# Print if verbose is set
verbose = (level, message) ->
  if commander.verbose >= level
    console.log "#{spaces(4 * (level-1))}#{message}"

# File helpers
# --------------------------------------------------------------------

isFile = (filePath) ->
  try
    (fs.statSync filePath).isFile()
  catch e
    false

isDirectory = (dirpath) ->
  try
    (fs.statSync dirpath).isDirectory()
  catch e
    false

# relativePathWithEscaping
# Example: '/User/name/folder1/file.oj' => '/file.oj'
relativePathWithEscaping = (fullPath, relativeTo) ->
  _.escapeSingleQuotes '/' + path.relative process.cwd(), fullPath

fullPaths = (relativePaths, dir) ->
  return _.map relativePaths, (p) -> path.join dir, p

# From a list of paths, find all directories and files
ls = (paths, cb, results = {files:[], directories:[]}) ->
  pending = paths.length
  breakIfDone = ->
    if pending == 0
      results.files = _.uniq results.files
      results.directories = _.uniq results.directories
      cb null, results

  for fullpath in paths
    do(fullpath) ->
      fs.stat fullpath, (err, stat) ->
        if stat?.isDirectory()
          fs.readdir fullpath, (err_, paths_) ->
            return cb err_ if err_
            results.directories.push fullpath
            paths_ = fullPaths paths_, fullpath
            # Recurse on children paths
            ls paths_, ((err3, res) -> breakIfDone --pending), results
        else
          results.files.push fullpath
          breakIfDone --pending
  breakIfDone()

readFileSync = (filePath) ->
  fs.readFileSync filePath, 'utf8'

_commonPath = (moduleName, moduleParentPaths) ->
  return null unless moduleName? and _.isArray moduleParentPaths
  for p in moduleParentPaths
    if _.startsWith moduleName, p + '/'
      return p + '/'
  null

# String helpers
# --------------------------------------------------------------------

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

_.insertAt = (str, ix, substr) ->
  str.slice(0,ix) + substr + str.slice(ix)

# Code minification
# --------------------------------------------------------------------

minifyJS = (filename, js, options = {}) ->
  verbose 3, "minifying #{filename}"
  try
    js = uglifyjs js, options
  catch e
    console.log "oj.command: could not minify: #{filename}"
    console.log e
    throw e

minifyCSS = (filename, css, structureOff = false) ->
  verbose 3, "minifying #{filename}"
  try
    css = csso.justDoIt css, structureOff
  catch e
    console.log "oj.command: could not minify: #{filename}"
    console.log e
    throw e

# Requiring
# --------------------------------------------------------------------

# Remember require references
_rememberModule = (modules, filename, code, module) ->
  verbose 2, "found #{filename}" if code
  modules[filename] = _.defaults {code: code, module: module}, (modules[filename] or {})

# Hooking into require inspired by http://github.com/fgnass/node-dev
_cacheHooks = {}
_cacheOrigs = {}
_hookRequire = (modules) ->
  handlers = require.extensions
  for ext of handlers
    # Get or create the hook for the extension
    hook = _cacheHooks[ext] or (_cacheHooks[ext] = _createHook(ext, modules))
    if handlers[ext] != hook
      # Save a reference to the original handler
      _cacheOrigs[ext] = handlers[ext]
      # and replace the handler by our hook
      handlers[ext] = hook

# Hook into one extension
_createHook = (ext, modules) ->
  return (module, filename) ->
    # Override compile to intercept file
    if !module.loaded
      _rememberModule modules, filename, null, module.paths

      # if path.extension filename _.indexOf ['.coffee']
      moduleCompile = module._compile
      module._compile = (code) ->
        _rememberModule modules, filename, code, module.paths
        return moduleCompile.apply this, arguments

    # Invoke the original handler
    _cacheOrigs[ext](module, filename)

    # Make sure the module did not hijack the handler
    _hookRequire modules

_nodeModulesSupported = oj:1, assert:1, console:1, crypto:1, events:1, freelist:1, path:1, punycode:1, querystring:1, string_decoder:1, tty:1, url:1, util:1
_nodeModuleUnsupported = child_process:1, domain:1, fs:1, net:1, os:1, vm:1, buffer:1
isNodeModule = (module) -> !!_nodeModulesSupported[module]
isUnsupportedNodeModule = (module) -> !!_nodeModuleUnsupported[module]
isAppModule = (module) -> (module.indexOf '/') == -1
isRelativeModule = (module) -> (module.indexOf '/') != -1

_requireCache = null
_saveRequireCache = ->
  _requireCache = _.clone require.cache

_restoreRequireCache = ->
  require.cache = _requireCache

# Clear one record. This does not work in general because
# it doesn't recurse. It does work on stand alone modules
# like 'path' and 'underscore'
_clearRequireCacheRecord = (record) ->
  delete require.cache[require.resolve record]

# Parse code with
_getRequiresInSource = (code) ->
  r = new RegExp("require\\s*\\(?\\s*[\"']([^\"']+)", 'g');
  out = []
  while match = r.exec code
    out.push match[1]
  out

_first = (array, fn) ->
  for x in array
    y = fn x
    return y if y

# Load all modules by reading them if they are missing
_buildRequireCache = (modules, cache) ->
  for filename, data of modules
    verbose 3, "building #{filename}",

    # Read code if it is missing
    if not data.code?
      data.code = stripBOM readFileSync filename

    # Save code to _fileCache
    _buildFileCache cache.files, filename, data.code, commander.debug

    pathComponents = _first module.parent.paths, (prefix) ->
      if _.startsWith filename, prefix + path.sep
        modulePath = (filename.slice (prefix.length + 1)).split(path.sep)
        moduleName = modulePath[0]
        moduleMain = modulePath.slice(1).join(path.sep)
        modulesDir: prefix, moduleName:  moduleName, moduleMain: moduleMain, moduleParentPath: module.id

    # Save to cache.native
    if pathComponents
      if not cache.modules[pathComponents.modulesDir]
        cache.modules[pathComponents.modulesDir] = {}
      # Example: /Users/evan/oj/node_modules: {underscore: 'underscore.js'}
      cache.modules[pathComponents.modulesDir][pathComponents.moduleName] = pathComponents.moduleMain

    # Build cache.native given source code in _fileCache
    _buildNativeCache cache.native, data.code, commander.debug

  # Remove local oj if it exists.
  # This is a special case of the way stuff is included.
  # To ourselves oj is local so that is what is auto
  # detected, but to them oj is native. Removing this
  # cache record ensures only the native copy persists.
  delete cache.files[require.resolve 'oj']

  return cache

# ###_buildFileCache: build file cache
_buildFileCache = (_filesCache, filename, code, isDebug) ->

  # Minify code if necessary
  verbose 3, "loading file #{filename}"  if isDebug
  if not isDebug
    code = minifyJS filename, code

  # Save code to _fileCache
  _filesCache[filename] = code

# build native module cache given moduleNameList
pass = 1

_buildNativeCache = (nativeCache, code, isDebug) ->
  # Get moduleName references from code
  moduleNameList = _getRequiresInSource code
  _buildNativeCacheFromModuleList nativeCache, moduleNameList, isDebug

_buildNativeCacheFromModuleList = (nativeCache, moduleNameList, isDebug) ->

  # Loop over modules and add them to native cache
  while moduleName = moduleNameList.shift()
    # Continue on already loaded native modules
    continue if nativeCache[moduleName]

    # OJ is built in
    if moduleName == 'oj'
      nativeCache.oj = _ojModuleCode isDebug

    # Do nothing if unsupported
    # Error checking happens earlier and missing modules at this stage are intentional
    else if isUnsupportedNodeModule moduleName
      pass

    else if isNodeModule moduleName
      # Get code
      codeModule = _nativeModuleCode moduleName, isDebug

      # Cache it
      nativeCache[moduleName] = codeModule

      # Concat all dependencies and continue on
      moduleNameList = moduleNameList.concat _getRequiresInSource codeModule

    else
      pass
  null

# ojModuleCode: Get code for oj
_ojModuleCode = (isDebug) ->
  code = readFileSync path.join __dirname, "../lib/oj.js"
  # Minify code if not debugging
  if not isDebug
    code = minifyJS 'oj', code
  code

# nativeModuleCode: Get code for native module
_nativeModuleCode = (moduleName, isDebug) ->
  verbose 3, "loading module #{moduleName}" if isDebug
  code = readFileSync path.join __dirname, "../modules/#{moduleName}.js"
  # Minify code if not debugging
  if not isDebug
    code = minifyJS moduleName, code
  code

# Templating
# =====================================================================

# Code generation
# --------------------------------------------------------------------

# ###_requireCacheToString
# Output html from cache and file
_requireCacheToString = (cache) ->
  # Maps from moduleDir -> moduleName -> moduleMain such that
  # the file path is: moduleDir/moduleName/moduleMain
  _modulesToString = (moduleDir, nameToMain) ->
    # Use relative path to hide server directory info
    moduleDir = relativePathWithEscaping moduleDir, process.cwd()
    "M['#{moduleDir}'] = #{JSON.stringify nameToMain};\n"

  # Maps moduleName -> code for built in "native" modules
  _nativeModuleToString = (moduleName, code) ->
    # Use relative path to hide server directory info
    moduleName = _.escapeSingleQuotes moduleName
    console.log "moduleName is undefined: ", moduleName if not code
    "N['#{moduleName}'] = (function(module,exports){(function(require,process,global,Buffer,__dirname,__filename){#{code}})(requirer('/'),P,G,B,'/','#{moduleName}');});\n"

  # Maps filePath -> code
  _fileToString = (filePath, code) ->
    # Use relative and escaped path
    filePath = relativePathWithEscaping filePath, process.cwd()
    fileDir = path.dirname filePath
    fileName = path.basename filePath
    "F['#{filePath}'] = (function(module,exports){(function(require,process,global,Buffer,__dirname,__filename){#{code}})(requirer('#{filePath}'),P,G,B,'#{fileDir}','#{fileName}');});\n"

  output =  """<script>
// Generated by oj v#{oj.version}
(function(){
var F = {}, M = {}, N = {}, R = {}, P, G, B;

// process
var P = {
  cwd: function(){return '/';}

}

// global
var G = {

}

// Buffer
var B = {

}

function code(m, f) {

  // Native
  if (N[m]){return N[m];}

  // Relative
  if(!!m.match(/\\//)){return path.join(path.dirname(f), m);}

  // App
  //else {}
}

function requirer(file){
  return function(module){
    c = code(module, file);
    var exports = {};
    var module = {exports:exports};
    c(module,exports);
    R[module] = m = module.exports;
    return m;
  };
}\n
"""

  # Save all the module info
  # { '/Users/evan/oj/node_modules': { underscore: 'underscore.js' } }
  for moduleDir, nameToMain of cache.modules
    output += _modulesToString moduleDir, nameToMain

  # Save all the files
  for filePath, code of cache.files
    verbose 3, "serializing file `#{filePath}`"
    output += _fileToString filePath, code

  # Save all the native modules
  for moduleName, code of cache.native
    verbose 3, "serializing module '#{moduleName}'"
    output += _nativeModuleToString moduleName, code

  output += """

window.require = requirer('/');
window.oj = require('oj');

}).call(this);
</script>
"""

  return output
