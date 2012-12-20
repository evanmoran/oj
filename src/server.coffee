
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
  args = _.extend {}, options,
    args: filesOrDirectories
    watch: true
  oj.command args

# oj.build
# ------------------------------------------------------------------------------

oj.build = (filesOrDirectories, options) ->
  args = _.extend {}, options,
    args: filesOrDirectories
    watch: false
  oj.command args

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
    compileOrWatch fullPath, options

# compileOrWatch
compileOrWatch = (fullPath, options = {}) ->
  if isDirectory fullPath
    if options.watch
      return watchDir fullPath, options
    return compileDir fullPath, options
  includeDir = path.dirname fullPath
  if options.watch
    return watchFile fullPath, includePath, options
  compileFile fullPath, includeDir, options

# compileDir
compileDir = (dirPath, options = {}) ->
  # Handle recursion and gather files to compile
  lsOjFiles dirPath, options, (err, files) ->
    options_ = _.clone options
    options_.root ?= dirPath
    for f in files
      compileFile f, dirPath, options_

# compileFile
# ------------------------------------------------------------------------------
compileFile = (filePath, includeDir, options = {}) ->

  # Clear underscore as modules might need it
  _clearRequireCacheRecord 'underscore'

  throw new Error('oj: file not found') unless isFile filePath

  # Default some values
  isDebug = options.debug or false
  includedModules = options.modules or []
  includedModules.concat ['oj', 'path']
  rootDir = options.root or path.dirname filePath

  throw new Error('oj: root is not a directory') unless isDirectory rootDir

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

  # Add user defined modules
  for m in includedModules
    if isNodeModule m
      _buildNativeCacheFromModuleList cache.native, [m], options.debug
      verbose 3, "found #{m}"
    else
      require m

  # Require this file to start the process
  ojml = require filePath
  html = (oj.compile debug: options.debug, ojml).html

  # Restore require cache
  _restoreRequireCache()
  _unhookRequire modules, hookCache, hookOriginalCache

  # Error if compiled file is missing required tags
  error "<html> tag is missing (#{filePath})" if html.indexOf('<html') == -1
  error "<body> tag is missing (#{filePath})" if html.indexOf('<body') == -1

  # Build cache
  verbose 2, "caching #{filePath} (#{_length modules} files)"
  cache = _buildRequireCache modules, cache, isDebug

  # Serialize cache
  cacheLength = _length(cache.files) + _length(cache.modules) + _length(cache.native)
  verbose 2, "serializing #{filePath} (#{cacheLength} files)"
  scriptHtml = _requireCacheToString cache, filePath, isDebug

  # Insert script into html just before </body>
  html = _insertAt html, (html.lastIndexOf '</body>'), scriptHtml

  # Create directory
  dirOut = path.dirname fileOut
  if mkdirp.sync dirOut
    verbose 3, "mkdir #{dirOut}"

  # Write file
  verbose 1, "compiled #{fileOut}"
  fs.writeFileSync fileOut, html

  # Clear caches
  cache = null
  hookCache = null
  hookOriginalCache = null

# watchFile
# ------------------------------------------------------------------------------

watchFile = (filePath, includeDir, options = {}) ->
  verbose 2, "watching #{filePath}"





# Helpers
# =====================================================================

# Output helpers
# ------------------------------------------------------------------------------

error = (message, exitCode = 1) ->
  console.log '\n  error:', message, "\n"
  process.exit exitCode

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

# lsOjFiles
# Abstract if recursion happened and filters to only files that don't start with _ and end in .oj

lsOjFiles = (paths, options, cb) ->
  options = _.extend {}, recurse: options.recurse, filter: (f) -> path.basename(f)[0] != '_' and path.extname(f) == '.oj'
  ls paths, options, (err, results) ->
    cb err, results.files
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

# Watch helpers
# ------------------------------------------------------------------------------

_watch = (source, base) ->
  prevStats = null
  compileTimeout = null

  _watchErr = (e) ->
    if e.code is 'ENOENT'
      return if sources.indexOf(source) is -1
      try
        _rewatch()
        _compile()
      catch e
        removeSource source, base, yes
        compileJoin()
    else throw e

  _compile = ->
    clearTimeout compileTimeout
    compileTimeout = wait 25, ->
      fs.stat source, (err, stats) ->
        return _watchErr err if err
        return _rewatch() if prevStats and stats.size is prevStats.size and
          stats.mtime.getTime() is prevStats.mtime.getTime()
        prevStats = stats
        fs.readFile source, (err, code) ->
          return _watchErr err if err
          compileFile source, code.toString(), base
          _rewatch()

  try
    watcher = fs.watch source, compile
  catch e
    _watchErr e

  _rewatch = ->
    watcher?.close()
    watcher = fs.watch source, compile


# Watch a directory of files for new additions.
watchDir = (filePath, base) ->
  readdirTimeout = null
  try
    watcher = fs.watch filePath, ->
      clearTimeout readdirTimeout
      readdirTimeout = wait 25, ->
        fs.readdir filePath, (err, files) ->
          if err
            throw err unless err.code is 'ENOENT'
            watcher.close()
            return unwatchDirectory filePath, base
          for file in files when not isHiddenFile(file) and not notSources[file]
            file = path.join filePath, file
            continue if sources.some (s) -> s.indexOf(file) >= 0
            sources.push file
            sourceCode.push null
            compileFile file, path.dirname(filePath), base
  catch e
    throw e unless e.code is 'ENOENT'

unwatchDirectory = (source, base) ->
  prevSources = sources[..]
  toRemove = (file for file in sources when file.indexOf(source) >= 0)
  removeSource file, base, yes for file in toRemove
  return unless sources.some (s, i) -> prevSources[i] isnt s
  compileJoin()

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
        return moduleCompile.apply this, arguments

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
  verbose 3, "found #{filename}" if code
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
    verbose 3, "stored #{filename}"

  # Remove client and server oj if they exist.
  # This is a special case of the way stuff is included.
  # To ourselves oj is local but to them oj is native.
  # Removing this cache record ensures only the native copy
  # is saved to the client.
  delete cache.files[require.resolve '../lib/oj.server.js']
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
    verbose 3, "serialized `#{filePath}`"

  # Client side code to include native modules
  _native = ""
  for moduleName, code of cache.native
    _native += _nativeModuleToString moduleName, code
    verbose 3, "serialized '#{moduleName}'"

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
  err = new Error();

  r = function(m){
    return run(find(m, f));
  };
  r.creationStack = err.stack;
  r.f = f;
  return r;
  #{_run}
  #{_find}
};

req = require = RR('#{path.join clientDir, clientFile}');
oj = require('oj');
oj('#{clientFile}');

}).call(this);

</script>
"""