
# server.coffee
# ==============================================================================
# Server side component of oj and the default include of nodejs
# Supports everything in oj plus building and watching files

# Include common
for m in ['path', 'fs', 'vm']
  global[m] = require m

_ = require 'underscore'
coffee = require 'coffee-script'
mkdirp = require 'mkdirp'
csso = require 'csso'
uglifyjs = require 'uglify-js'

# Run in the context of the dom and jquery
jsdom = (require 'jsdom').jsdom
global.$ = require 'jquery'
global.document = jsdom "<html><head></head><body></body></html>"
global.window = document.createWindow()

# Export server side oj
oj = require './oj'
oj.isClient = false
oj.codes =
  reset: '\u001b[0m'
  black: '\u001b[30m'
  red: '\u001b[31m'
  green: '\u001b[32m'
  yellow: '\u001b[33m'
  blue: '\u001b[34m'
  magenta: '\u001b[35m'
  cyan: '\u001b[36m'
  gray: '\u001b[37m'
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

# Remember verbosity level
verbosity = null

oj.command = (options = {}) ->

  verbosity = options.verbose || 1
  options.watch ?= false

  # Verify args exist
  throw new Error('oj: no args found') unless (_.isArray options.args) and options.args.length > 0

  # Convert args to full paths
  options.args = fullPaths options.args, process.cwd()

  for fullPath in options.args
    compilePath fullPath, options

  return

# compilePath
# ------------------------------------------------------------------------------
# Compile any file or directory path

compilePath = (fullPath, options = {}, cb = ->) ->
  if isDirectory fullPath
    return compileDir fullPath, options, cb
  includeDir = path.dirname fullPath
  compileFile fullPath, includeDir, options, cb
  return

# compileDir
# ------------------------------------------------------------------------------

compileDir = (dirPath, options = {}, cb = ->) ->
  # Handle recursion and gather files to watch and compile
  lsWatch dirPath, options, (err, files, dirs) ->

    # Watch all directories if option is set
    if options.watch
      for d in dirs
        watchDir d, dirPath, options

    # Call cb when it has been called length times
    _cb = _.after files.length, cb

    for f in files

      # Compile and watch all pages
      if isOJPage f
        compileFile f, dirPath, options, _cb

      # Watch files that aren't pages
      else if options.watch
        watchFile f, dirPath, options
        _cb()
    return
  return

# nodeModulePaths: Determine node_module paths from a given path
# Implementation is from node.js' Module._nodeModulePaths
# This is not a public API so it seemed to horrible.
nodeModulePaths = (from) ->
  from = path.resolve from
  splitRe = (if process.platform == 'win32' then  /[\/\\]/ else /\//)
  joiner = (if process.platform == 'win32' then '\\' else '/')
  paths = []
  parts = from.split splitRe
  for tip in [(parts.length-1)..0]
    # Don't search in .../node_modules/node_modules
    if parts[tip] == 'node_modules'
      continue
    dir = parts.slice(0, tip + 1).concat('node_modules').join(joiner)
    paths.push(dir)
  paths

# Recursively get final link path
resolveLink = (linkPath, out) ->
  try
    newPath = fs.readlinkSync linkPath
    return (resolveLink newPath, newPath)
  catch e
  out

# Get module mapping from link dest to link source
# /some/path/linked-module  -> /another/path/node_modules/linked-module
nodeModulesLinkMap = (fileDir) ->
  dirs = nodeModulePaths fileDir
  out = {}
  for dir in dirs
    try
      modules = fs.readdirSync dir
      for moduleName in modules
        modulePath = path.join dir, moduleName
        linkPath = resolveLink modulePath
        if linkPath?
          out[linkPath] = modulePath
    catch e
  out

# basenameForExtensions: Get basename for multiple extensions
basenameForExtensions = (p, arrayOfExt = []) ->
  out = path.basename p
  for ext in arrayOfExt
    out = path.basename out, ext
  out

# compileFile
# ------------------------------------------------------------------------------
compileFile = (filePath, includeDir, options = {}, cb = ->) ->
  # Time this method
  startTime = process.hrtime()

  # Clear underscore as modules might need it
  _clearRequireCacheRecord 'underscore'

  throw new Error('oj: file not found') unless isFile filePath

  # Default some values
  isDebug = options.debug or false
  includedModules = options.modules or []
  includedModules = includedModules.concat ['oj']
  rootDir = options.root or path.dirname filePath

  throw new Error('oj: root is not a directory') unless isDirectory rootDir

  # Watch file if option is set
  if options.watch
    watchFile filePath, includeDir, options

  # Figure out some paths
  #    /input/dir/file.oj

  #    /input/dir
  fileDir = path.dirname filePath

  #    /output
  outputDir = options.output || process.cwd()

  #    /dir
  subDir = path.relative includeDir, fileDir

  #    /output/dir/file.html
  fileBaseName = basenameForExtensions filePath, ['.oj', '.ojc', 'ojlc']
  fileOut = path.join outputDir, subDir, fileBaseName + '.html'

  verbose 2, "compiling #{filePath}"

  # Cache of modules, files, and native modules
  cache = modules:{}, files:{}, native:{}

  # Determine global modules with soft linking
  moduleLinkMap = nodeModulesLinkMap fileDir

  # Hook require to intercept requires in oj files
  modules = {}
  moduleParents = {}  # map file name to parent list
  hookCache = {}
  hookOriginalCache = {}
  _hookRequire modules, moduleLinkMap, hookCache, hookOriginalCache

  # Save require cache to restore it later
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

    # Unwind ourselves from require before failing
    _restoreRequireCache()
    _unhookRequire modules, hookCache, hookOriginalCache
    return

  # Restore require cache
  _restoreRequireCache()
  _unhookRequire modules, hookCache, hookOriginalCache

  # Watch needs records of file dependencies
  _rememberModuleDependencies modules

  # Catch the messages thrown by compiling ojml
  try
    # Compile
    results = oj.compile debug:isDebug, html:true, css:true, dom:false, ojml
    html = results.html
    css = results.css
  catch eCompile
    error "runtime error in #{filePath}: #{eCompile.message}"
    return

  # Build cache
  verbose 3, "caching #{filePath} (#{_length modules} files)"
  cache = _buildRequireCache modules, cache, isDebug

  # Serialize cache
  cacheLength = _length(cache.files) + _length(cache.modules) + _length(cache.native)
  verbose 3, "serializing #{filePath} (#{cacheLength} files)"
  scriptHtml = _requireCacheToString cache, filePath, isDebug

  if !results.tags.html
    error "validation error #{filePath}: <html> tag is missing"
    return

  else if !results.tags.head
    error "validation error #{filePath}: <head> tag is missing"
    return

  else if !results.tags.body
    error "validation error #{filePath}: <body> tag is missing"
    return

  # TODO: Should we check for doctype?
  # Insert script before </body> or before </html> or at the end
  scriptIndex = html.lastIndexOf '</body>'
  html = _insertAt html, scriptIndex, scriptHtml

  # Insert styles before </head> or after <html> or at the beginning
  if css
    try
      styleHtml = _minifyAndWrapCSSInStyleTags css, filePath, isDebug
      styleIndex = html.lastIndexOf '</head>'
      html = _insertAt html, styleIndex, styleHtml
    catch eCSS
      error "css minification error #{filePath}: #{eCSS.message}"
      error "generated css: #{css}"
      return
  # Create directory
  dirOut = path.dirname fileOut
  if mkdirp.sync dirOut
    verbose 3, "mkdir #{dirOut}"

  # Record
  deltaTime = process.hrtime(startTime)
  timeStamp = " (#{deltaTime[0] + Math.round(10000*deltaTime[1]/1000000000)/10000} sec)"

  # Clear caches
  cache = null
  hookCache = null
  hookOriginalCache = null

  # Write file
  fs.writeFile fileOut, html, (err) ->

    if err
      error "file writing error #{filePath}: #{err}"
      return

    verbose 1, "compiled #{fileOut}#{timeStamp}", 'cyan'
    return

# Keep track of which files are watched
watchCache = {}
isWatched = (fullPath) ->
  watchCache[fullPath]?
triggerWatched = (fullPath) ->
  watchCache[fullPath]?._events?.change?()
# Keep track of dependency tree of files
watchParents = {}

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
        verbose 2, "unwatching missing file: #{filePath}", 'yellow'
        _unwatch()
    else throw e

  timeLast = new Date(2000)
  timeEpsilon = 2 # milliseconds

  _onWatch = ->
    try
      clearTimeout compileTimeout
      compileTimeout = wait 0.025, ->

        # Ignore recompiles within epsilon time
        timeNow = new Date()
        return if (timeNow - timeLast) / 1000 < timeEpsilon
        timeLast = timeNow

        # Files that aren't pages should trigger their parents
        if not isOJPage filePath
          parents = watchParents[filePath]
          if parents?
            for parent in parents
              triggerWatched parent

        # Files that are pages should recompile
        else
          fs.stat filePath, (err, stats) ->
            return _watchErr err if err
            verbose 2, "updating file #{filePath}", 'yellow'
            compileFile filePath, includeDir, options

    catch e
      verbose 1, 'unknown watch error on #{filePath}'
      _unwatch()
  try
    verbose 2, "watching file #{filePath}", 'yellow'
    watcher = fs.watch filePath, _onWatch
    watchCache[filePath] = watcher
  catch e
    _watchErr e

  _rewatch = ->
    verbose 3, "rewatch file #{filePath}", 'yellow'
    _unwatch()

    watchCache[filePath] = watcher = fs.watch filePath, _onWatch

  _unwatch = ->
    if isWatched filePath
      watchCache[filePath].close()
    watchCache[filePath] = null

# watchDir
# ------------------------------------------------------------------------------

# Watch a directory of files for new additions.
# This method does not recurse as it is called from methods that do (compileDir)
watchDir = (dir, includeDir, options) ->

  # Short circuit if already watching this directory
  return if isWatched dir

  # Throttle
  compileTimeout = null

  verbose 2, "watching directory #{dir}/", 'yellow'
  watcher = fs.watch dir, (err) ->
    verbose 2, "updating directory #{dir}/", 'yellow'

    # Unwatch missing directories
    if err and not isDirectory dir
      return unwatchDir dir

    # When the directory changes a file may have been added or removed
    # Watch all the directories and files that aren't currently being watched
    lsOJ dir, options, (err, files, dirs) ->
      for d in dirs
        if not isWatched d
          watchDir d
      for f in files
        if not isWatched f
          compileFile f, includeDir, options

  # Cache watch
  watchCache[dir] = watcher
  return

unwatchDir = (dir) ->
  verbose 2, "unwatching #{dir}/", 'yellow'
  if isWatched dir
    watchCache[dir].close()
  watchCache[dir] = null
  return

unwatchAll = ->
  verbose 2, "unwatching all files and directories", 'yellow'
  for k in _.keys watchCache
    if watchCache[k]?
      watchCache[k].close()
      watchCache[k] = null

# Cleanup watches on exit
process.on 'SIGINT', ->
  verbose 1, "\n"
  unwatchAll()
  verbose 1, "oj exited successfully.", 'cyan'
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
verbose = (level, message, color = 'reset') ->
  if verbosity >= level
    console.log oj.codes[color] + "#{spaces(4 * (level-1))}#{message}" + oj.codes.reset

error = (message) ->
  red = oj.codes?.red ? ''
  reset = oj.codes?.red ? ''
  console.error "#{red}#{message}#{reset}"
  return

# File helpers
# ------------------------------------------------------------------------------

# isFile: Determine if path is to a file
isFile = (filePath) ->
  try
    (fs.statSync filePath).isFile()
  catch e
    false

isOJFile = (filePath) ->
  ext = path.extname filePath
  ext == '.oj' or ext == '.ojc'

# isOJPage: Determine if path is an oj page.
isOJPage = (filePath) ->
  ext = path.extname filePath
  base = path.basename filePath
  (isOJFile filePath) and base[0] != '_'and base.slice(0,2) != 'oj' and not isHiddenFile filePath

# isWatchFile: Determine if file can be required and therefore is worth watching
isWatchFile = (filePath) ->
  ext = path.extname filePath
  (isOJFile filePath) or ext == '.js' or ext == '.coffee' or ext == '.json'

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
  _.map relativePaths, (p) -> path.resolve dir, p

# commonPath: Given a list of full paths. Find the common root
commonPath = (paths, seperator = '/') ->
  if paths.length == 1
    return path.dirname paths[0]

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
# Abstract if recursion happened and filters to only files that don't start with _ and end in an oj filetype (.oj, .ojc, .ojlc)

lsOJ = (paths, options, cb) ->
  # Choose visible files with extension `.oj` and don't start with `oj` (plugins) or `_` (partials & templates)
  options = _.extend {}, recurse: options.recurse, filter: (f) -> isOJPage f

  ls paths, options, (err, results) ->
    cb err, results.files, results.directories
  return

# lsWatch
# Look for all files I should consider watching.
# This includes: .js, .coffee, .oj, .ojc, with no limitations on
# hidden, underscore or oj prefixes.

lsWatch = (paths, options, cb) ->
  # Choose visible files with extension `.oj` and don't start with `oj` (plugins) or `_` (partials & templates)
  options = _.extend {}, recurse: options.recurse, filter: (f) -> isWatchFile f
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
  js = uglifyjs js, options

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
  css = csso.justDoIt css, structureOff

minifyCSSUnless = (isDebug, filename, css, structureOff) ->
  return css if isDebug
  return minifyCSS filename, css, structureOff

# Requiring
# ------------------------------------------------------------------------------

# Hooking into require inspired by [node-dev](http://github.com/fgnass/node-dev)
_hookRequire = (modules, moduleLinkMap, hookCache={}, hookOriginalCache={}) ->
  handlers = require.extensions
  for ext of handlers
    # Get or create the hook for the extension
    hook = hookCache[ext] or (hookCache[ext] = _createHook(ext, modules, moduleLinkMap, hookCache, hookOriginalCache))
    if handlers[ext] != hook
      # Save a reference to the original handler
      hookOriginalCache[ext] = handlers[ext]
      # and replace the handler by our hook
      handlers[ext] = hook
  return

# Hook into one extension
_createHook = (ext, modules, moduleLinkMap, hookCache, hookOriginalCache) ->
  (module, filename) ->

    # Unfortunately require resolves `filename` through soft links
    # For our module detection to work we need to unresolve these back
    # Use the moduleLinkMap to unresolve paths starting with `linkPath`
    # to start with `modulePath` instead.
    for linkPath, modulePath of moduleLinkMap
      # Prefix found then replace
      if 0 == filename.indexOf linkPath
        rest = filename.slice linkPath.length
        filename = modulePath + rest
        # break

    # Override compile to intercept file
    if !module.loaded
      _rememberModule modules, filename, null, module.parent.filename

      # if path.extension filename _.indexOf ['.coffee']
      moduleCompile = module._compile
      module._compile = (code) ->
        _rememberModule modules, filename, code, module.parent.filename
        moduleCompile.apply this, arguments
        return

    # Invoke the original handler
    hookOriginalCache[ext](module, filename)

    # Make sure the module did not hijack the handler
    _hookRequire modules, moduleLinkMap, hookCache, hookOriginalCache

_unhookRequire = (modules, hookCache, hookOriginalCache) ->
  handlers = require.extensions
  for ext of handlers
    if hookCache[ext] == handlers[ext]
      handlers[ext] = hookOriginalCache[ext]
  hookCache = null
  hookOriginalCache = null
  return

# Remember require references
_rememberModule = (modules, filename, code, parent) ->
  verbose 3, "requiring #{filename}" if code
  modules[filename] = _.defaults {code: code, parent:parent}, (modules[filename] or {})

_rememberModuleDependencies = (modules) ->
  for filename, module of modules
    watchParents[filename] ?= []
    watchParents[filename].push module.parent
    watchParents[filename] = _.unique watchParents[filename]

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
  for fileLocation, data of modules

    # Read code if it is missing
    if not data.code?
      throw new Error('data.code is missing')
      # data.code = stripBOM readFileSync fileLocation

    # Save code to _fileCache
    _buildFileCache cache.files, fileLocation, data.code, isDebug

    # Generate possible node_module paths given this file
    modulePrefixes = nodeModulePaths fileLocation

    pathComponents = _first modulePrefixes, (prefix) ->
      if _startsWith fileLocation, prefix + path.sep
        modulePath = (fileLocation.slice (prefix.length + 1)).split(path.sep)
        moduleName = modulePath[0]
        moduleMain = modulePath.slice(1).join(path.sep)
        modulesDir: prefix, moduleName:  moduleName, moduleMain: moduleMain, moduleParentPath: module.id

    # Save to cache.modules
    if pathComponents
      if not cache.modules[pathComponents.modulesDir]
        cache.modules[pathComponents.modulesDir] = {}
      # Example: /Users/evan/oj/node_modules: {underscore: 'underscore.js'}
      cache.modules[pathComponents.modulesDir][pathComponents.moduleName] = pathComponents.moduleMain

    # Build cache.native given source code in _fileCache
    _buildNativeCache cache.native, data.code, isDebug

    # Store complete
    verbose 4, "stored #{fileLocation}"

  # Remove client and server oj if they exist.
  # This is a special case of the way stuff is included.
  # To ourselves oj is local but to them oj is native.
  # Removing this cache record ensures only the native copy
  # is saved to the client.
  delete cache.files[require.resolve '../lib/oj.js']

  return cache

# ###_buildFileCache: build file cache
_buildFileCache = (_filesCache, fileName, code, isDebug) ->
  # Minify code if necessary and cache it
  _filesCache[fileName] = minifyJSUnless isDebug, fileName, code

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

# ###_minifyAndWrapCSSInStyleTags
# Wrap css in script tags and possibly minify it
_minifyAndWrapCSSInStyleTags = (css, filePath, isDebug, structureOff) ->
  css_ = minifyCSSUnless isDebug, filePath, css, structureOff
  newline = if isDebug then '\n' else ''
  "<style>#{newline}#{css_}#{newline}</style>"

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
  clientFile = _escapeSingleQuotes '/' + basenameForExtensions filePath, ['.ojc', '.oj', '.coffee', '.js']

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

  # Browser side node has these abbreviations:
  #     G = Global
  #     P = Process
  #     RR = Require factory to generated require for a given path
  #     R = Require cache
  #     F = File cache
  #     M = Module cache

  # Client side function to run module and cache result
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
  _find = minifySimpleJSUnless isDebug, """
  function find(m,f){
      var r, dir, dm, ext, ex, i;

      if (F[m] && !m.match(/\\//)) {
        return m;
      }

      if (!!m.match(/\\//)) {
        r = oj.__.pathResolve(f, oj.__.pathJoin(oj.__.pathDirname(f), m));
        ext = ['.ojc','.oj','.coffee','.js','.json'];
        for(i = 0; i < ext.length; i++){
          ex = ext[i];
          if(F[r+ex])
            return r+ex;
        }
      } else {
        dir = oj.__.pathDirname(f);
        while(true) {
          dm = oj.__.pathJoin(dir, 'node_modules');
          if(M[dm] && M[dm][m])
            return oj.__.pathJoin(dm, m, M[dm][m]);
          if(dir == '/')
            break;
          dir = oj.__.pathResolve(dir, '..');
        }
      }
      throw new Error("module not found (" + m + ")");
    }
  """

  return """
<script>

// Generated with oj v#{oj.version}
(function(){ var F = {}, M = {}, R = {}, P, G, RR;

#{_modules}#{_files}#{_native}
P = {cwd: function(){return '/';}};
G = {process: P,Buffer: {}};
RR = function(f){
  return function(m){
    return run(find(m, f));
  };
  #{_run}
  #{_find}
};

require = RR('#{path.join clientDir, clientFile}');
oj = require('oj');
oj.begin('#{clientFile}');

}).call(this);

</script>
"""

# Express
# ==============================================================================
# app.engine
# app.use('view engine', 'ojc')
oj.express = ->
  console.log "express called"
