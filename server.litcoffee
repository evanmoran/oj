
server.coffee
==============================================================================
Static website creator for oj and the npm module
Express templating engine and middleware

  Include common modules

    for m in ['path', 'fs', 'vm']
      global[m] = require m

  Include dependencies

    _ = require 'underscore'
    coffee = require 'coffee-script'
    mkdirp = require 'mkdirp'
    csso = require 'csso'
    uglifyjs = require 'uglify-js'

  Static site creation runs in the context of the dom and jQuery

    jsdom = (require 'jsdom').jsdom
    global.jQuery = global.$ = require 'jquery'
    global.document = jsdom "<html><head></head><body></body></html>"
    global.window = document.createWindow()

Export Server Side OJ
-------------------------------------------------------------------------------

  Include the client library in this module

    oj = require '../oj'

  Indicate it is server side

    oj.isClient = false

  Export this module

    module.exports = oj

  Make sure jquery is hooked up

    oj.$ = global.$

  Store console codes for color logging

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

Register require.extension for .oj and .ojc file types
-------------------------------------------------------------------------------

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

  Compile .oj files as javascript

      require.extensions['.oj'] = (module, filepath) ->
        # Ensure absolute paths are found correctly for oj file types
        if filepath[0] == '/' && filepath != module.filename
          filepath = module.filename

        # Read the file
        code = stripBOM fs.readFileSync filepath, 'utf8'
        try
          compileJS module, code, filepath
        catch eJS
          eJS.message = wrapJSMessage eJS.message, filepath
          throw eJS

  Compile .ojc files as coffee-script

      require.extensions['.ojc'] = (module, filepath) ->
        # Ensure absolute paths are found correctly for oj file types
        if filepath[0] == '/' && filepath != module.filename
          filepath = module.filename

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

Commands
==============================================================================

oj.watch
------------------------------------------------------------------------------
Watch list of files or directories

    oj.watch = (filesOrDirectories, options) ->
      options = _.extend {}, options,
        args: filesOrDirectories
        watch: true
        write: true
      oj.command options

oj.build
------------------------------------------------------------------------------
Build list of files or directories

    oj.build = (filesOrDirectories, options) ->
      options = _.extend {}, options,
        args: filesOrDirectories
        watch: false
        write: true
      oj.command options

oj.command
------------------------------------------------------------------------------

Remember verbosity level

    verbosity = null

oj.command options:

  * args: list of files or directories
  * debug: bool
  * watch: bool
  * recurse: bool
  * output: directory/path
  * modules: list of strings to include manually
  * verbose: level
  * html: Only output html
  * css: Only output css
  * js: Only output page js (no modules)
  * modules: Only output modules (no page rendering)

Define command

    oj.command = (options = {}) ->

      verbosity = options.verbose || 1
      options.watch ?= false    # Watch for changes and recompile
      options.write ?= true     # Output to a file
      options.recurse ?= true   # Recurse in sub directories
      options.include ?= []     # Include modules
      options.exclude ?= []     # Exclude modules

  Default to all when no output options are specified

      options.html ?= false
      options.css ?= false
      options.js ?= false
      options.modules ?= false

      if options.all or (!options.html and !options.css and !options.js and !options.modules)
        options.modules = options.js = options.css = options.html = true

  Resolve directory args to full path and append / to ensure path prefixes refer to directories

      options.output = (path.resolve process.cwd(), (options.output ? www)) + '/'
      options.modulesDir = (path.resolve process.cwd(), (options.modulesDir ? './modules')) + '/'

  cssDir is optional

      if options.cssDir
        options.cssDir = (path.resolve process.cwd(), options.cssDir) + '/'

  Verify output directory isn't the root directory

      if options.output == process.cwd()
        error('oj: output directory cannot be current directory')
        return

  Verify args exist

      throw new Error('oj: no args found') unless (_.isArray options.args) and options.args.length > 0

  Convert args to full paths

      options.args = fullPaths options.args, process.cwd()

      for fullPath in options.args
        compilePath fullPath, options

      return

compilePath
------------------------------------------------------------------------------
Compile any file or directory path

    compilePath = (fullPath, options = {}, cb = ->) ->
      if isDirectory fullPath
        return compileDir fullPath, options, cb
      includeDir = path.dirname fullPath
      compileFile fullPath, includeDir, options, cb

compileDir
------------------------------------------------------------------------------

    compileDir = (dirPath, options = {}, cb = ->) ->
      # Handle recursion and gather files to watch and compile
      lsWatch dirPath, options, (err, files, dirs) ->
        console.log "lsWATCH CB CALLED"
        console.log "files: ", files
        console.log "dirs: ", dirs
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

nodeModulePaths: Determine node_module paths from a given path
------------------------------------------------------------------------------
Implementation is from node.js' Module._nodeModulePaths
This is not a public API so it seemed to horrible.

    nodeModulePaths = (from) ->
      from = path.resolve from
      splitRe = (if process.platform == 'win32' then  /[\/\\]/ else /\//)
      joiner = (if process.platform == 'win32' then '\\' else '/')
      paths = []
      parts = from.split splitRe
      for tip in [(parts.length-1)..0]

  Don't search in .../node_modules/node_modules

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

  Get module mapping from link dest to link source
  /some/path/linked-module  -> /another/path/node_modules/linked-module

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

compileFile
------------------------------------------------------------------------------

    compileFile = (filePath, includeDir, options = {}, cb = ->) ->
      options = _.clone options

      # Time this method
      startTime = process.hrtime()

      # Clear underscore as modules might need it
      _clearRequireCacheRecord 'underscore'

      options.exclude ?= []

      throw new Error('oj: file not found') unless isFile filePath

      # Default some values
      isMinify = options.minify ? false

      includedModules = options.include or []
      includedModules = includedModules.concat ['oj', 'jquery']

      rootDir = options.root or path.dirname filePath
      fileDir = path.dirname filePath

      # Directory specifications win over options every time
      if _startsWith filePath, options.modulesDir
        options.modules = true
        options.css = false
        options.html = false
        options.js = false
      else if options.cssDir and _startsWith filePath, options.cssDir
        console.log "css dir found"
        options.modules = false
        options.css = true
        options.html = false
        options.js = false

      throw new Error('oj: root is not a directory') unless isDirectory rootDir

      # Watch file if option is set
      if options.watch
        watchFile filePath, includeDir, options

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

      # Remove excluded
      for ex in options.exclude
        verbose 3, "excluding #{ex}"
      includedModules = _.difference includedModules, options.exclude

      # Catch messages thrown by requiring
      try

        # Require user defined modules
        for m in includedModules
          if isNodeModule m
            _buildNativeCacheFromModuleList cache.native, [m], isMinify
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

  Compile css if --css is set

      cssOption = !!options.css

  Compile html only if --html is set

      htmlOption = !!options.html

  Create compile options

      compileOptions = minify:isMinify, html:htmlOption, cssMap:cssOption, css:cssOption, dom:false
      # Catch the messages thrown by compiling ojml
      try
        # Compile
        results = oj.compile compileOptions, ojml
      catch eCompile
        error "runtime error in #{filePath}: #{eCompile.message}"
        return

      # Build cache
      verbose 3, "caching #{filePath} (#{_length modules} files)"
      cache = _buildRequireCache modules, cache, isMinify

  Calculate file locations for outputing

      # (assuming filePath is /input/dir/file.oj)
      # fileBaseName = file
      fileBaseName = basenameForExtensions filePath, ['.oj', '.ojc', 'ojlc']
      # outputDir = /output
      outputDir = options.output || process.cwd()
      # fileDir = /input/dir
      fileDir = path.dirname filePath
      # subDir = /dir
      subDir = path.relative includeDir, fileDir

  Calculate the file extension. Default is .html

      extOut = '.html'

  Use .css if only --css is specified

      if options.css and not (options.html or options.js or options.modules)
        extOut = '.css'

  Use .js if css and html aren't specified

      else if (options.js or options.modules) and not (options.html or options.css)
        extOut = '.js'

  Calculate file path to output to

      # fileOut = /output/dir/file.html
      fileOut = path.join outputDir, subDir, fileBaseName + extOut

  Extend info to calculate output file locations and other meta data

      options.info = _.extend {},
        includeDir: includeDir
        # Profiling data
        startTime: startTime
        # Results of compile
        results: results
        # Module cache
        cache: cache
        filePath: filePath
        fileDir: fileDir
        fileBaseName: fileBaseName
        outputDir: outputDir
        subDir: subDir
        extOut: extOut
        fileOut: fileOut
        isMinify: isMinify

      _outputFile options, cb

      return

    # _outputFile:
    # Generic output file function that takes cached state and options and does the right thing
    # including options for:
    #   options.write:false output to callback instead of file
    # ------------------------------------------------------------------------------
    _outputFile = (options, cb) ->
      # Output html only as a .html
      if options.html and not (options.css or options.js or options.modules)
        _outputHtml options, cb
      # Output css as a .css file
      else if options.css and not (options.html or options.js or options.modules)
        _outputCss options, cb
      # Output js, modules or both as a .js file
      else if (options.js or options.modules) and not (options.html or options.css)
        _outputJs options, cb
      # Output some combination of html,css,js and modules in a .html file
      else
        _outputCombinedHtml options, cb

    # outputUnifed
    # ------------------------------------------------------------------------------

    _outputCombinedHtml = (options, cb) ->

      info = options.info
      results = info.results
      filePath = info.filePath
      fileOut = info.fileOut
      html = results.html
      cssMap = results.cssMap
      cache = info.cache
      cacheLength = _length(cache.files) + _length(cache.modules) + _length(cache.native)
      verbose 3, "serializing #{filePath} (#{cacheLength} files)"
      scriptHtml = _requireCacheToHtml cache, filePath, options.minify ? false, options

      if !results.tags.html
        error "validation error #{filePath}: <html> tag is missing"
        return

      else if !results.tags.head
        error "validation error #{filePath}: <head> tag is missing"
        return

      else if !results.tags.body
        error "validation error #{filePath}: <body> tag is missing"
        return

      # TODO: Should we auto-insert doctype 5?
      # Insert script before </body> or before </html> or at the end
      scriptIndex = html.lastIndexOf '</body>'
      html = _insertAt html, scriptIndex, scriptHtml

      # Insert styles before </head> or after <html> or at the beginning
      styleIndex = html.indexOf '</head>'
      styleHTML = ''
      for plugin,mediaMap of results.cssMap
        styleHTML += oj._styleTagFromMediaObject plugin, mediaMap, options
      html = _insertAt html, styleIndex, styleHTML

      _outputDataToFileOrCallback html, options, cb

    # _outputCss
    # ------------------------------------------------------------------------------

    _outputCss = (options, cb) ->
      _outputDataToFileOrCallback options.info.results.css, options, cb

    # _outputHtml
    # ------------------------------------------------------------------------------
    _outputHtml = (options, cb) ->
      _outputDataToFileOrCallback options.info.results.html, options, cb

    # _outputJs
    # ------------------------------------------------------------------------------
    _outputJs = (options, cb) ->
      info = options.info
      js = _requireCacheToJS info.cache, info.filePath, info.isMinify, options
      _outputDataToFileOrCallback js, options, cb

    # _outputDataToFileOrCallback
    # ------------------------------------------------------------------------------
    # Output data to the fileOut location taking into account options.write flag
    # If options.write is set the file is outputed otherwise it is sent only to the cb
    _outputDataToFileOrCallback = (data, options, cb) ->

      info = options.info
      fileOut = info.fileOut

      filePath = info.filePath
      fileOut = info.fileOut

      # Create directory
      dirOut = path.dirname fileOut
      if mkdirp.sync dirOut
        verbose 3, "mkdir #{dirOut}"

      timeStamp = _timeStampFromStartTime info.startTime

      # Write file
      if options.write

        fs.writeFile fileOut, data, (err) ->
          if err
            error "file writing error #{filePath}: #{err}"
            return

          verbose 1, "compiled #{fileOut}#{timeStamp}", 'cyan'
          cb(null, data)
          return
      else
        verbose 1, "compiled #{fileOut}#{timeStamp}", 'cyan'
        cb(null, data)

    _timeStampFromStartTime = (startTime) ->
      deltaTime = process.hrtime(startTime)
      timeStamp = " (#{deltaTime[0] + Math.round(10000*deltaTime[1]/1000000000)/10000} sec)"

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

watchDir
------------------------------------------------------------------------------
Watch a directory of files for new additions.
This method does not recurse as it is called from methods that do (compileDir)

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

renderPath
------------------------------------------------------------------------------
Render a file as a view. Used by express plugin

    renderPath = (path, options, cb) ->
      compilePath(path, {write:false, minify:false}, cb)

Helpers
===============================================================================

Output helpers
-------------------------------------------------------------------------------

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
      reset = oj.codes?.reset ? ''
      console.error "#{red}#{message}#{reset}"
      return

File helpers
------------------------------------------------------------------------------

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

    # isOJDir: Determine if path is an oj directory.
    isOJDir = (dirPath, outputDir) ->
      base = path.basename dirPath
      base[0] != '_'and base[0] != '.' and base != 'node_modules'

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
    # Abstract if recursion happened and filters to only files / directories that don't start with _ and end in an oj filetype (.oj, .ojc, .ojlc)

    lsOJ = (paths, options, cb) ->
      options ?= {}

      # Choose visible files with extension `.oj` and don't start with `oj` (plugins) or `_` (partials & templates)
      options = _.extend {},
        recurse: options.recurse
        filterFile: ((f) -> isOJPage f)
        filterDir:((d) -> isOJDir d)

      ls paths, options, (err, files, dirs) ->
        cb err, files, dirs
      return

    # lsWatch
    # Look for all files I should consider watching.
    # This includes: .js, .coffee, .oj, .ojc, with no limitations on
    # hidden, underscore or oj prefixes.

    lsWatch = (paths, options, cb) ->

      # Choose visible files with extension `.oj` and don't start with `oj` (plugins) or `_` (partials & templates)
      lsOptions = _.extend {},
        recurse: options.recurse,
        filterFile: isWatchFile
        filterDir:(nameWithPath) ->
          # Doesn't start with output directory and fits isOJDir criteria
          !(_startsWith nameWithPath, options.output) and isOJDir nameWithPath

      ls paths, lsOptions, (err, files, dirs) ->
        cb err, files, dirs
      return

ls: List directories and files from paths asynchronously
  options.filterFile: accept those files that return true
  options.filterDir: accept those directories that return true
  options.recurse: boolean to indicate recursion is desired

    ls = (fullPath, options, cb, acc) ->

      # Optional options
      if _.isFunction options
        cb = options
        options = {}

      options ?= {}
      options.recurse ?= false
      options.filterFile ?= -> true # Keep everything by default
      options.filterDir ?= -> true # Keep everything by default
      options.recurseDepth ?= if options.recurse then Infinity else 1

      acc ?= {}
      acc.files ?= []
      acc.dirs ?= []
      acc.pending ?= 1

      breakIfDone = ->
        if acc.pending == 0
          files = _.uniq acc.files
          dirs = _.uniq acc.dirs
          cb null, files, dirs
        return

      fs.stat fullPath, (err, stat) ->
        return cb err if err
        # File calculated
        --acc.pending

        # File found
        if stat.isFile() and options.filterFile(fullPath)
          acc.files.push fullPath
          return breakIfDone()

        # Directory found
        else if stat.isDirectory() and options.filterDir(fullPath)
          acc.dirs.push fullPath

          fs.readdir fullPath, (errReadDir, paths) ->
            return cb errReadDir if errReadDir

            if !paths or paths.length == 0
              return breakIfDone()

            # Directory has contents
            acc.pending += paths.length

            paths = fullPaths paths, fullPath

            # Recurse if we haven't hit max depth
            if options.recurseDepth > 0
              options_ = _.clone options
              options_.recurseDepth--
              for fullPath_ in paths
                ls fullPath_, options_, cb, acc

        else
          return breakIfDone()

      return

    readFileSync = (filePath) ->
      fs.readFileSync filePath, 'utf8'

Timing helpers
------------------------------------------------------------------------------

    wait = (seconds, fn) -> setTimeout fn, seconds*1000

String helpers
------------------------------------------------------------------------------

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
      throw new Error('startsWith: argument error') unless (_.isString strInput) and (_.isString strStart)
      strInput.length >= strStart.length and strInput.lastIndexOf(strStart, 0) == 0

    _escapeSingleQuotes = (str) ->
      str.replace /'/g, "\\'"

    _insertAt = (str, ix, substr) ->
      str.slice(0,ix) + substr + str.slice(ix)

    _length = (any) ->
      any.length or _.keys(any).length

Code minification
------------------------------------------------------------------------------

    oj._minifyJS = (js, options = {}) ->

      if options.filename
        verbose 4, "minified #{options.filename}"

      if options.minify
        uglifyjs js
      else
        js

    oj._minifyCSS = (css, options = {}) ->
      if options.minify
        csso.justDoIt css, true # true means apply structural changes
      else
        css

Requiring
------------------------------------------------------------------------------

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

    _nodeModulesSupported = oj:1, jquery:1, assert:1, console:1, crypto:1, events:1, freelist:1, path:1, punycode:1, querystring:1, string_decoder:1, tty:1, url:1, util:1
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

    # Build out the cache into the form:
    #   cache.native = ['oj','jquery',...]
    #   cache.modules = {<path/to/node_modules>: {<moduleName>:<path/to/main/file.js, ...}, ...}
    #   cache.files = {<path/to/files.js>:<code>}

    _buildRequireCache = (modules, cache, isMinify) ->
      for fileLocation, data of modules
        console.log "fileLocation: ", fileLocation

        # Read code if it is missing
        if not data.code?
          throw new Error('data.code is missing')
          # data.code = stripBOM readFileSync fileLocation

        # Save code to _fileCache
        _buildFileCache cache.files, fileLocation, data.code, isMinify

        # Generate possible node_module paths given this file
        modulePrefixes = nodeModulePaths fileLocation

        pathComponents = _first modulePrefixes, (prefix) ->
          if _startsWith fileLocation, prefix + path.sep
            modulePath = (fileLocation.slice (prefix.length + 1)).split(path.sep)
            moduleName = modulePath[0]
            moduleMain = modulePath.slice(1).join(path.sep)
            modulesDir: prefix, moduleName:  moduleName, moduleMain: moduleMain, moduleParentPath: module.id

        # Save to cache.modules
        console.log "pathComponents: ", pathComponents
        if pathComponents
          if not cache.modules[pathComponents.modulesDir]
            cache.modules[pathComponents.modulesDir] = {}
          # Example: /Users/evan/oj/node_modules: {underscore: 'underscore.js'}
          cache.modules[pathComponents.modulesDir][pathComponents.moduleName] = pathComponents.moduleMain

        # Build cache.native given source code in _fileCache
        _buildNativeCache cache.native, data.code, isMinify

        # Store complete
        verbose 4, "stored #{fileLocation}"

      # Remove client and server oj if they exist.
      # This is a special case of the way stuff is included.
      # To ourselves oj is local but to them oj is native.
      # Removing this cache record ensures only the native copy
      # is saved to the client.
      delete cache.files[require.resolve '../oj.js']

      # Separate files into three parts so each can be outputed separately:
      #   moduleFiles, pageFiles, nativeFiles
      cache.nativeFiles = cache.native
      cache.moduleFiles = {}
      cache.pageFiles = {}
      for filePath, code of cache.files
        console.log "filePath: ", filePath
        if filePath.indexOf("/node_modules/") != -1
          cache.moduleFiles[filePath] = code
        else
          cache.pageFiles[filePath] = code
      console.log "\n\n"
      console.log "_.keys cache.moduleFiles: ", _.keys cache.moduleFiles
      console.log "_.keys cache.pageFiles: ", _.keys cache.pageFiles
      console.log "cache.modules: ", cache.modules
      return cache

    # ###_buildFileCache: build file cache
    _buildFileCache = (_filesCache, fileName, code, isMinify) ->
      # Minify code if necessary and cache it
      _filesCache[fileName] = oj._minifyJS code, {filename:fileName, minify: isMinify}

    # build native module cache given moduleNameList
    pass = 1

    _buildNativeCache = (nativeCache, code, isMinify) ->
      # Get moduleName references from code
      moduleNameList = _getRequiresInSource code
      _buildNativeCacheFromModuleList nativeCache, moduleNameList, isMinify

    _buildNativeCacheFromModuleList = (nativeCache, moduleNameList, isMinify) ->

      # Loop over modules and add them to native cache
      while moduleName = moduleNameList.shift()

        # Continue on already loaded native modules
        continue if nativeCache[moduleName]

        # OJ is built in
        if moduleName == 'oj'
          nativeCache.oj = _ojModuleCode isMinify

        # Do nothing if unsupported
        # Error checking happens earlier and missing modules at this stage are intentional
        else if isUnsupportedNodeModule moduleName
          pass

        else if isNodeModule moduleName
          # Get code
          codeModule = _nativeModuleCode moduleName, isMinify

          # Cache it
          nativeCache[moduleName] = codeModule

          # Concat all dependencies and continue on
          moduleNameList = moduleNameList.concat _getRequiresInSource codeModule

        else
          pass
      null

    # ojModuleCode: Get code for oj
    _ojModuleCode = (isMinify) ->
      code = readFileSync path.join __dirname, "../oj.js"
      oj._minifyJS code, filename:'oj', minify:isMinify

    # nativeModuleCode: Get code for native module
    _nativeModuleCode = (moduleName, isMinify) ->
      verbose 3, "found #{moduleName}"
      code = readFileSync path.join __dirname, "../modules/#{moduleName}.js"

Templating
==============================================================================

Code generation
------------------------------------------------------------------------------

    # ###_requireCacheToHtml
    _requireCacheToHtml = (cache, filePath, isMinify, options) ->
      return """
        <script>
        #{_requireCacheToJS cache, filePath, isMinify, options}
        </script>
      """

    # ###_requireCacheToJS
    # Output html from cache and file
    _requireCacheToJS = (cache, filePath, isMinify, options) ->
      newline = if isMinify then '' else '\n'

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
        """F['#{moduleName}'] = (function(module,exports){(function(process,global,__dirname,__filename){#{newline}#{code}})(P,G,'/','#{moduleName}');});\n"""

      # Maps filePath -> code
      _fileToString = (filePath, code, prefixWithRequire) ->
        # Use relative and escaped path
        filePath = relativePathWithEscaping filePath, commonDir
        fileDir = path.dirname filePath
        fileName = path.basename filePath
        out = if prefixWithRequire then "require." else ""
        out += """F['#{filePath}'] = (function(module,exports){(function(require,process,global,__dirname,__filename){#{newline}#{code}})(require.RR('#{filePath}'),require.P,require.G,'#{fileDir}','#{fileName}');});#{newline}\n"""

      # Client side code to include modules
      _modules = ""
      # { '/Users/evan/oj/node_modules': { underscore: 'underscore.js' } }
      for moduleDir, nameToMain of cache.modules
        _modules += _modulesToString moduleDir, nameToMain

      # Client side code to include files from modules and from pages
      _moduleFiles = ""
      for filePath, code of cache.moduleFiles
        _moduleFiles += _fileToString filePath, code
        verbose 4, "serialized module file `#{filePath}`"

      _pageFiles = ""
      # Prefix require if modules aren't being output with this
      prefixWithRequire = !options.modules
      for filePath, code of cache.pageFiles
        _pageFiles += _fileToString filePath, code, prefixWithRequire
        verbose 4, "serialized page file `#{filePath}`"

      # Client side code to include native modules
      _nativeFiles = ""
      for moduleName, code of cache.native
        _nativeFiles += _nativeModuleToString moduleName, code
        verbose 4, "serialized native file '#{moduleName}'"

      # Browser side node has these abbreviations:
      #     G = Global
      #     P = Process
      #     RR = Require factory to generated require for a given path
      #     R = Require cache
      #     F = File cache
      #     M = Module cache

      # Client side function to run module and cache result
      _run = oj._minifyJS """
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
    """, minify:isMinify

      # Client side function to find module
      _find = oj._minifyJS """
      function find(m,f){
          var r, dir, dm, ext, ex, i;

          if (F[m] && !m.match(/\\//))
            return m;

          if (!!m.match(/\\//)) {
            r = oj._pathResolve(f, oj._pathJoin(oj._pathDirname(f), m));
            ext = ['.ojc','.oj','.coffee','.js','.json'];
            for(i = 0; i < ext.length; i++){
              ex = ext[i];
              if(F[r+ex])
                return r+ex;
            }
          } else {
            if (typeof oj !== 'undefined') {
              dir = oj._pathDirname(f);
              while(true) {
                dm = oj._pathJoin(dir, 'node_modules');
                if(M[dm] && M[dm][m])
                  return oj._pathJoin(dm, m, M[dm][m]);
                if(dir == '/')
                  break;
                dir = oj._pathResolve(dir, '..');
              }
            }
          }
          throw new Error("module not found (" + m + ")");
        }
      """, minify: isMinify

      # Begin function
      js = """
        // Generated with oj v#{oj.version}
        ;(function(){
      """

  Add modules if we want to include them

      if options.modules
        js += """
          var M = {}, F = {}, R = {}, P, G, RR;

          // Package modules
          #{_modules}
          #{_moduleFiles}
          // Native modules
          #{_nativeFiles}
          // Define node environment: process P, global G and require factory RR
          P = {cwd: function(){return '/'}}
          G = {process: P,Buffer: {}}
          RR = function(f){
            var o = function(m){return run(find(m, f))};
            o.P = P; o.G = G; o.F = F; o.M = M, o.RR = RR;
            return o;
            #{_run}
            #{_find}
          };

          // Define require and oj
          require = RR('/');
          oj = require('oj');\n
        """

  Include page js if we want to include it

      if options.js
        js += """
          \n// Page files
          #{_pageFiles}
          oj.load('#{clientFile}');\n
        """
      # End function
      js += """
        }).call(this);
      """

Express
==============================================================================

    oj.__express = renderPath
