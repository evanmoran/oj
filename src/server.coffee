
# server.coffee
# ==============================================================================
# Server side component of oj and the default include of nodejs
# Supports everything in oj plus building and watching files

path = require 'path'
fs = require 'fs'
vm = require 'vm'

_ = require 'underscore'
coffee = require 'coffee-script'
mkdirp = require 'mkdirp'
csso = require 'csso'
uglifyjs = require 'uglify-js'

oj = require './oj'

verbosity = null

module.exports = oj

# Commands
# ==============================================================================

# oj.watch
# ------------------------------------------------------------------------------

oj.watch = (filesOrDirectories, options) ->
  options = _.extend {}, options,
    args: filesOrDirectories
    watch: true
  oj.command options

# oj.build
# ------------------------------------------------------------------------------

oj.build = (filesOrDirectories, options) ->
  options = _.extend {}, options,
    args: filesOrDirectories
    watch: false
  oj.command options

# oj.command
# ------------------------------------------------------------------------------
#     options.args (list of files or directories)
#     options.debug (bool)
#     options.watch (bool)
#     options.recurse (bool)
#     options.output (directory/path)
#     options.modules (list of strings to include manually)
#     options.verbose <level>

oj.command = (options = {}) ->

  verbosity = options.verbose || 1
  options.watch ?= false

  # Verify args exist
  throw new Error('oj: no args found') unless (_.isArray options.args) and options.args.length > 0

  # Convert args to full paths
  options.args = fullPaths options.args, process.cwd()

  for fullPath in options.args
    compilePath fullPath, options

# compilePath
# Compile any file or directory path
compilePath = (fullPath, options = {}) ->
  if isDirectory fullPath
    return compileDir fullPath, options
  includeDir = path.dirname fullPath
  compileFile fullPath, includeDir, options

# compileDir
compileDir = (dirPath, options = {}) ->
  # Handle recursion and gather files to compile
  lsOJ dirPath, options, (err, files, dirs) ->

    # Watch all directories if option is set
    if options.watch
      for d in dirs
        watchDir d, dirPath, options

    # Compile all files
    for f in files
      compileFile f, dirPath, options

# compileFile
# ------------------------------------------------------------------------------
compileFile = (filePath, includeDir, options = {}) ->

  # Clear underscore as modules might need it
  _clearRequireCacheRecord 'underscore'

  throw new Error('oj: file not found') unless isFile filePath

  # Default some values
  isDebug = options.debug or false
  includedModules = options.modules or []
  includedModules = includedModules.concat ['oj', 'path']
  rootDir = options.root or path.dirname filePath

  throw new Error('oj: root is not a directory') unless isDirectory rootDir

  # Watch file if option is set
  if options.watch
    watchFile filePath, includeDir, options

  # Figure out some paths
  #    /input/dir/file.oj

  #    /output
  outputDir = options.output || process.cwd()

  #    /dir
  subDir = path.relative includeDir, path.dirname filePath

  #    /output/dir/file.html
  fileOut = path.join outputDir, subDir, (path.basename filePath, '.oj') + '.html'

  verbose 2, "compiling #{filePath}"

  # Cache of modules, files, and native modules
  cache = modules:{}, files:{}, native:{}

  # Hook require to intercept requires in oj files
  modules = {}
  hookCache = {}
  hookOriginalCache = {}
  _hookRequire modules, hookCache, hookOriginalCache

  # Save require cache
  _saveRequireCache()

  # Catch messages thrown by requiring
  try

    # Require user defined modules
    for m in includedModules
      if isNodeModule m
        _buildNativeCacheFromModuleList cache.native, [m], options.debug
      else
        verbose 3, "including #{m}"
        require m

    # Require this file to start the process
    ojml = require filePath

  # Abort require with message on failure
  catch eRequire
    verbose 1, eRequire.message
    return

  # Restore require cache
  _restoreRequireCache()
  _unhookRequire modules, hookCache, hookOriginalCache

  # Compile
  results = oj.compile debug: options.debug, ojml
  html = results.html

  # Error if compiled file is missing required <html> or <body>
  if html.indexOf('<html') == -1
    return verbose 1, "(error) #{filePath}: <html> tag is missing"

  if html.indexOf('<body') == -1
    return verbose 1, "(error) #{filePath}: <body> tag is missing"

  # Build cache
  verbose 3, "caching #{filePath} (#{_length modules} files)"
  cache = _buildRequireCache modules, cache, isDebug

  # Serialize cache
  cacheLength = _length(cache.files) + _length(cache.modules) + _length(cache.native)
  verbose 3, "serializing #{filePath} (#{cacheLength} files)"
  scriptHtml = _requireCacheToString cache, filePath, isDebug

  # Insert script into html just before </body>
  html = _insertAt html, (html.lastIndexOf '</body>'), scriptHtml

  # Create directory
  dirOut = path.dirname fileOut
  if mkdirp.sync dirOut
    verbose 3, "mkdir #{dirOut}"

  # Write file
  timeStamp = if options.watch then "#{(new Date()).toLocaleTimeString()} - " else ""
  verbose 1, "#{timeStamp}compiled #{fileOut}"
  fs.writeFileSync fileOut, html

  # Clear caches
  cache = null
  hookCache = null
  hookOriginalCache = null


# Keep track of which files are watched
watchCache = {}
isWatched = (fullPath) ->
  watchCache[fullPath]?

# watchFile
# ------------------------------------------------------------------------------
# Based in part on coffee-script's watch implementation
# github.com/jashkenas/coffee-script/

watchFile = (filePath, includeDir, options = {}) ->

  # Do nothing if this file is already watched
  return if isWatched filePath

  prevStats = null
  compileTimeout = null

  _watchErr = (e) ->
    if e.code is 'ENOENT'
      try
        _rewatch()
        _compile()
      catch e
        verbose 2, "unwatching missing file: #{filePath}"
        _unwatch()
    else throw e

  timeLast = new Date(2000)
  timeEpsilon = 2 # seconds
  _compile = ->

    # Ignore recompiles within epsilon time
    timeNow = new Date()
    return if (timeNow - timeLast) / 1000 < timeEpsilon

    timeLast = timeNow

    try
      clearTimeout compileTimeout
      compileTimeout = wait 0.025, ->
        fs.stat filePath, (err, stats) ->
          return _watchErr err if err
          return _rewatch() if prevStats and stats.size is prevStats.size and
            stats.mtime.getTime() is prevStats.mtime.getTime()
          verbose 3, "updating #{filePath}"
          prevStats = stats
          compileFile filePath, includeDir, options
    catch e
      # TODO: Consider if this is necessary
      verbose 1, 'unknown watch error on #{filePath}'
      _unwatch()
  try
    verbose 2, "watching #{filePath}"
    watcher = fs.watch filePath, _compile
    watchCache[filePath] = watcher
  catch e
    _watchErr e

  _rewatch = ->
    verbose 3, 'rewatch #{filePath}'
    _unwatch()

    watchCache[filePath] = watcher = fs.watch filePath, _compile

  _unwatch = ->
    if isWatched filePath
      watchCache[filePath].close()
    watchCache[filePath] = null

# watchDir
# ------------------------------------------------------------------------------

# Watch a directory of files for new additions.
# This method does not recurse as it is called from methods that do (compileDir)
watchDir = (dir, includeDir, options) ->

  # Short circut if already watching this directory
  return if isWatched dir

  # Throttle
  compileTimeout = null

  verbose 2, "watching #{dir}/"
  watcher = fs.watch dir, (err) ->
    verbose 3, "updating #{dir}/"

    # Unwatch missing directories
    if err and not isDirectory dir
      return unwatchDir dir

    # When the directory changes a file may have been added or removed
    # Watch all the directories and files that aren't currently being watched
    lsOJ dir, options, (err, files, dirs) ->
      for d in dirs
        watchDir d
      for f in files
        if not isWatched f
          compileFile f, includeDir, options

  # Cache watch
  watchCache[dir] = watcher
  return

unwatchDir = (dir) ->
  verbose 2, "unwatching #{dir}/"
  if isWatched dir
    watchCache[dir].close()
  watchCache[dir] = null
  return

unwatchAll = ->
  verbose 2, "unwatching all files and directories"
  for k in _.keys watchCache
    if watchCache[k]?
      watchCache[k].close()
      watchCache[k] = null

# Cleanup watches on exit
process.on 'SIGINT', ->
  verbose 1, "\n"
  unwatchAll()
  verbose 1, "oj exited successfully."
  process.exit()

# Helpers
# =====================================================================

# Output helpers
# ------------------------------------------------------------------------------

success = ->
  process.exit 0

tabs = (count) ->
  Array(count + 1).join('\t')

spaces = (count) ->
  Array(count + 1).join(' ')

# Print if verbose is set
verbose = (level, message) ->
  if verbosity >= level
    console.log "#{spaces(4 * (level-1))}#{message}"

# File helpers
# ------------------------------------------------------------------------------

# isFile: Determine if path is to a file
isFile = (filePath) ->
  try
    (fs.statSync filePath).isFile()
  catch e
    false

# isHiddenFile: Determine if file is hidden
isHiddenFile = (file) -> /^\.|~$/.test file

# isDirectory: Determine if path is to directory
isDirectory = (dirpath) ->
  try
    (fs.statSync dirpath).isDirectory()
  catch e
    false

# relativePathWithEscaping
# Example: '/User/name/folder1/file.oj' => '/file.oj'
relativePathWithEscaping = (fullPath, relativeTo) ->
  _escapeSingleQuotes '/' + path.relative relativeTo , fullPath

# fullPaths: Convert relative paths to full paths from origin dir
fullPaths = (relativePaths, dir) ->
  _.map relativePaths, (p) -> path.join dir, p

# commonPath: Given a list of full paths. Find the common root
commonPath = (paths, seperator = '/') ->
  common = paths[0].split seperator
  ixCommon = common.length
  for p in paths
    parts = p.split seperator
    for part, ixPart in parts
      if common[ixPart] != part or ixPart > ixCommon
        break
    ixCommon = Math.min ixPart, ixCommon
  if ixCommon == 1 && paths[0][0] == seperator
    return seperator
  else if ixCommon == 0
    return null
  (common.slice 0, ixCommon).join seperator

# lsOJ
# Abstract if recursion happened and filters to only files that don't start with _ and end in .oj

lsOJ = (paths, options, cb) ->
  options = _.extend {}, recurse: options.recurse, filter: (f) -> path.basename(f)[0] != '_' and path.extname(f) == '.oj' and not isHiddenFile f
  ls paths, options, (err, results) ->
    cb err, results.files, results.directories
  return

# ls
# List directories and files from paths asynchronously
# options.filter: accept those files that return true
# options.recurse: boolean to indicate recursion is desired

ls = (paths, options, cb) ->
  # Default paths to an array
  paths = [paths] unless _.isArray paths

  # Optional options
  if _.isFunction options
    cb = options
    options = {}
  options ?= {}
  options.results ?= files:[], directories:[]
  options.recurse ?= false
  options.filter ?= -> true # Keep everything by default

  pending = paths.length
  breakIfDone = ->
    if pending == 0
      options.results.files = _.uniq (_.filter options.results.files, options.filter)
      options.results.directories = _.uniq options.results.directories
      cb null, options.results
    return

  for p in paths
    do(p) ->
      # Stat them all
      fs.stat p, (err, stat) ->
        # File found
        if not stat?.isDirectory()
          # Store it
          options.results.files.push p
          breakIfDone --pending

        # Directory found
        else
          # Store it
          options.results.directories.push p

          # List it
          fs.readdir p, (errReadDir, paths_) ->

            # Handle error
            return cb errReadDir if errReadDir

            # Convert to full paths
            paths_ = fullPaths paths_, p

            # Track extra async calls from fs.stat
            pending += paths_.length

            # Stat them and store the files
            for p_ in paths_
              do(p_) ->
                fs.stat p_, (errStat, stat_) ->

                  # Handle error
                  return cb errStat if errStat

                  # File found
                  if not stat_?.isDirectory()
                    options.results.files.push p_
                    breakIfDone --pending
                    return

                  # Recurse if necessary
                  if options.recurse
                    ls p_, options, -> breakIfDone --pending
                  else
                    breakIfDone --pending
                  return

            breakIfDone --pending

  breakIfDone()
  return

readFileSync = (filePath) ->
  fs.readFileSync filePath, 'utf8'

_commonPath = (moduleName, moduleParentPaths) ->
  return null unless moduleName? and _.isArray moduleParentPaths
  for p in moduleParentPaths
    if _startsWith moduleName, p + '/'
      return p + '/'
  null

# Timing helpers
# ------------------------------------------------------------------------------

wait = (seconds, fn) -> setTimeout fn, seconds*1000

# String helpers
# ------------------------------------------------------------------------------

trimArgList = (v) ->
  _trim v.split(',')

# trim
_trim = (any) ->
  if _.isString any
    any.trim()
  else if _.isArray any
    out = _.map any, (v) -> v.trim()
    _.reject out, ((v) -> v == '' or v == null)
  else
    any

# startsWith
_startsWith = (strInput, strStart) ->
  throw 'startsWith: argument error' unless (_.isString strInput) and (_.isString strStart)
  strInput.length >= strStart.length and strInput.lastIndexOf(strStart, 0) == 0

_escapeSingleQuotes = (str) ->
  str.replace /'/g, "\\'"

_insertAt = (str, ix, substr) ->
  str.slice(0,ix) + substr + str.slice(ix)

_length = (any) ->
  any.length or _.keys(any).length

# Code minification
# ------------------------------------------------------------------------------

minifyJS = (filename, js, options = {}) ->
  verbose 4, "minified #{filename}" if filename
  try
    js = uglifyjs js, options
  catch e
    console.log "oj.command: could not minify: #{filename}" if filename
    console.log e
    throw e

minifyJSUnless = (isDebug, filename, js, options) ->
  return js if isDebug
  return minifyJS filename, js, options

minifySimpleJS = (js, options = {}) ->
  js = js.replace /\n/g, ''
  js.replace /\s\s+/g, ' '

minifySimpleJSUnless = (isDebug, js, options) ->
  return js if isDebug
  return minifySimpleJS js, options

minifyCSS = (filename, css, structureOff = false) ->
  verbose 4, "minified #{filename}" if filename
  try
    css = csso.justDoIt css, structureOff
  catch e
    console.log "oj.command: could not minify: #{filename}" if filename
    console.log e
    throw e

minifyCSSUnless = (isDebug, filename, css, structureOff) ->
  return css if isDebug
  return minifyCSS filename, css, structureOff

# Requiring
# ------------------------------------------------------------------------------

# Hooking into require inspired by http://github.com/fgnass/node-dev
_hookRequire = (modules, hookCache={}, hookOriginalCache={}) ->
  handlers = require.extensions
  for ext of handlers
    # Get or create the hook for the extension
    hook = hookCache[ext] or (hookCache[ext] = _createHook(ext, modules, hookCache, hookOriginalCache))
    if handlers[ext] != hook
      # Save a reference to the original handler
      hookOriginalCache[ext] = handlers[ext]
      # and replace the handler by our hook
      handlers[ext] = hook
  return

# Hook into one extension
_createHook = (ext, modules, hookCache, hookOriginalCache) ->
  (module, filename) ->
    # Override compile to intercept file
    if !module.loaded
      _rememberModule modules, filename, null, module.paths

      # if path.extension filename _.indexOf ['.coffee']
      moduleCompile = module._compile
      module._compile = (code) ->
        _rememberModule modules, filename, code, module.paths
        moduleCompile.apply this, arguments
        return

    # Invoke the original handler
    hookOriginalCache[ext](module, filename)

    # Make sure the module did not hijack the handler
    _hookRequire modules, hookCache, hookOriginalCache

_unhookRequire = (modules, hookCache, hookOriginalCache) ->
  handlers = require.extensions
  for ext of handlers
    if hookCache[ext] == handlers[ext]
      handlers[ext] = hookOriginalCache[ext]
  hookCache = null
  hookOriginalCache = null
  return

# Remember require references
_rememberModule = (modules, filename, code, module) ->
  verbose 3, "requiring #{filename}" if code
  modules[filename] = _.defaults {code: code, module: module}, (modules[filename] or {})

_nodeModulesSupported = oj:1, assert:1, console:1, crypto:1, events:1, freelist:1, path:1, punycode:1, querystring:1, string_decoder:1, tty:1, url:1, util:1
_nodeModuleUnsupported = child_process:1, domain:1, fs:1, net:1, os:1, vm:1, buffer:1
isNodeModule = (module) -> !!_nodeModulesSupported[module]
isUnsupportedNodeModule = (module) -> !!_nodeModuleUnsupported[module]
isAppModule = (module) -> (module.indexOf '/') == -1
isRelativeModule = (module) -> (module.indexOf '/') != -1

# _saveRequireCache
# Save a record of the cache so we can restore it later
_requireCache = null
_saveRequireCache = ->
  _requireCache = _.clone require.cache

# _restoreRequireCache
# Remove all recoreds in the cache that weren't there before
_restoreRequireCache = ->
  for k of require.cache
    delete require.cache[k] unless _requireCache[k]?

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
_buildRequireCache = (modules, cache, isDebug) ->
  for filename, data of modules

    # Read code if it is missing
    if not data.code?
      data.code = stripBOM readFileSync filename

    # Save code to _fileCache
    _buildFileCache cache.files, filename, data.code, isDebug

    pathComponents = _first module.parent.paths, (prefix) ->
      if _startsWith filename, prefix + path.sep
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
    _buildNativeCache cache.native, data.code, isDebug

    # Store complete
    verbose 4, "stored #{filename}"

  # Remove client and server oj if they exist.
  # This is a special case of the way stuff is included.
  # To ourselves oj is local but to them oj is native.
  # Removing this cache record ensures only the native copy
  # is saved to the client.
  delete cache.files[require.resolve './index.js']
  delete cache.files[require.resolve '../lib/oj.js']

  return cache

# ###_buildFileCache: build file cache
_buildFileCache = (_filesCache, filename, code, isDebug) ->
  # Minify code if necessary and cache it
  _filesCache[filename] = minifyJSUnless isDebug, filename, code

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
  minifyJSUnless isDebug, 'oj', code

# nativeModuleCode: Get code for native module
_nativeModuleCode = (moduleName, isDebug) ->
  verbose 3, "found #{moduleName}" if isDebug
  code = readFileSync path.join __dirname, "../modules/#{moduleName}.js"
  # Minify code if not debugging
  minifyJSUnless isDebug, moduleName, code

# Templating
# ==============================================================================

# Code generation
# ------------------------------------------------------------------------------

# ###_requireCacheToString
# Output html from cache and file
_requireCacheToString = (cache, filePath, isDebug) ->
  # Example:
  #   filePath: /User/name/project/www/file.oj
  #   commonDir: /User/name/project
  #   clientDir: /www
  #   clientfile: /file

  # Calculate common path root between all cached files
  commonDir = commonPath _.keys cache.files

  # Determine directory for client using common path
  clientDir = _escapeSingleQuotes '/' + path.relative commonDir, path.dirname filePath

  # Determine file for client given the above directory
  clientFile = _escapeSingleQuotes '/' + path.basename filePath, '.oj'

  # Maps from moduleDir -> moduleName -> moduleMain such that
  # the file path is: moduleDir/moduleName/moduleMain
  _modulesToString = (moduleDir, nameToMain) ->
    # Use relative path to hide server directory info
    moduleDir = relativePathWithEscaping moduleDir, commonDir
    "M['#{moduleDir}'] = #{JSON.stringify nameToMain};\n"

  # Maps moduleName -> code for built in "native" modules
  _nativeModuleToString = (moduleName, code) ->
    # Use relative path to hide server directory info
    moduleName = _escapeSingleQuotes moduleName
    console.log "moduleName is undefined: ", moduleName if not code
    """F['#{moduleName}'] = (function(module,exports){(function(process,global,__dirname,__filename){#{code}})(P,G,'/','#{moduleName}');});\n"""

  # Maps filePath -> code
  _fileToString = (filePath, code) ->
    # Use relative and escaped path
    filePath = relativePathWithEscaping filePath, commonDir
    fileDir = path.dirname filePath
    fileName = path.basename filePath
    """F['#{filePath}'] = (function(module,exports){(function(require,process,global,__dirname,__filename){#{code}})(RR('#{filePath}'),P,G,'#{fileDir}','#{fileName}');});\n"""

  # Client side code to include modules
  _modules = ""
  # { '/Users/evan/oj/node_modules': { underscore: 'underscore.js' } }
  for moduleDir, nameToMain of cache.modules
    _modules += _modulesToString moduleDir, nameToMain

  # Client side code to include files
  _files = ""
  for filePath, code of cache.files
    _files += _fileToString filePath, code
    verbose 4, "serialized `#{filePath}`"

  # Client side code to include native modules
  _native = ""
  for moduleName, code of cache.native
    _native += _nativeModuleToString moduleName, code
    verbose 4, "serialized '#{moduleName}'"

  # Client side function to run module and cache result
    #console.log("run: file:", f);
  _run = minifySimpleJSUnless isDebug, """
  function run(f){
      if(R[f] != null)
        return R[f];
      var eo = {},
        mo = {exports: eo};
      if(typeof F[f] != 'function')
        throw new Error("file not found (" + f + ")");
      F[f](mo,eo);
      return R[f] = mo.exports;
    }
"""

  # Client side function to find module
    #console.log('find: module:', m, ' file:', f);
  _find = minifySimpleJSUnless isDebug, """
  function find(m,f){
      var r, p, dir, dm, ext, ex, i;

      if (F[m] && !m.match(/\\//)) {
        return m;
      }

      p = require('path');

      if (!!m.match(/\\//)) {
        r = p.resolve(f, p.join(p.dirname(f), m));
        ext = ['.oj','.coffee','.js','.json'];
        for(i = 0; i < ext.length; i++){
          ex = ext[i];
          if(F[r+ex])
            return r+ex;
        }
      } else {
        dir = p.dirname(f);
        while(true) {
          dm = p.join(dir, 'node_modules');
          if(M[dm] && M[dm][m])
            return p.join(dm, m, M[dm][m]);
          if(dir == '/')
            break;
          dir = p.resolve(dir, '..');
        }
      }
      throw new Error("module not found (" + m + ")");
    }
  """

  return """
<script>

// oj v#{oj.version}
(function(){ var F = {}, M = {}, R = {}, P, G, RR;

#{_modules}
#{_files}
#{_native}
P = {cwd: function(){return '/';}};
G = {process: P,Buffer: {}};

RR = function(f){
  return function(m){
    return run(find(m, f));
  };
  #{_run}
  #{_find}
};

req = require = RR('#{path.join clientDir, clientFile}');
oj = require('oj');
oj('#{clientFile}');

}).call(this);

</script>
"""