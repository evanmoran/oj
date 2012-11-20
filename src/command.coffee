_ = require 'underscore'
commander = require 'commander'
path = require 'path'
fs = require 'fs'
vm = require 'vm'
oj = require './oj'
includer = require './includer'
coffee = require 'coffee-script'

module.exports = ->

  commander.version('0.0.3')
    .usage('[options] <file, ...>')
    .option('-o, --output <dir>', 'Directory to output all files to (default: .)', process.cwd())
    .option('    --css <dir>', 'Directory to output css files to (default: .)')
    .option('    --js <dir>', 'Directory to output js files to (default: .)')
    .option('    --html <dir>', 'Directory to output css files to (default: .)')
    .option('-r, --recurse', 'Recurse into directories (default: off)', false)
    .option('-w, --watch <dir,dir,...>', 'Directories to watch (default: off)', trimArgList)
    .option('-v, --verbose', 'Turn on verbose output (default: off)')
    .parse(process.argv)

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

  console.log "commander.files: ", commander.files
  for filePath in commander.files
    compile filePath


compile = (file, options = {}) ->

  nodeModules = ['assert', 'console', 'crypto', 'events', 'freelist', 'path', 'punycode', 'string_decoder', 'url', 'util']
  nodeModuleUnsupported = ['fs', 'vm', 'net', 'os', 'tty']

  isNodeModule = (module) -> (_.indexOf nodeModules, module) != -1
  isUnsupportedNodeModule = (module) -> (_.indexOf nodeModuleUnsupported, module) != -1
  isAppModule = (module) -> (module.indexOf '/') == -1
  isRelativeModule = (module) -> (module.indexOf '/') != -1

  wrapper = [
    '(function (exports, require, module, __filename, __dirname) {\n ',
    '\n});'
  ]
  wrap = (source) ->
    wrapper[0] + source + wrapper[1]

  console.log "compile called with options: ", options
  fullPath = path.resolve file

  error "file not found (#{fullPath})" unless isFile fullPath

  directory = path.dirname fullPath
  include = includer(directory)
  fs.readFile fullPath, 'utf8', (err, code) ->
    throw new Error(err) if err

    try
      code = coffee.compile code
    catch e
      # Do nothing already javascript! (hopefully)

    scopedOJ = _.extend {}, oj, include: include
    scope = _.extend {}, global, scopedOJ, oj: scopedOJ

    scopedRequire = (modulePath) ->
      if isUnsupportedNodeModule modulePath
        throw new Error 'oj.compile: #{modulePath} module is unsupported in oj files'

      else if isNodeModule modulePath
        console.log "node module found: ", modulePath
        return requireAndPrint modulePath

      else if isRelativeModule modulePath
        console.log "relative module found: ", modulePath
        return requireAndPrint path.join directory, modulePath

      else if isAppModule modulePath
        console.log "app module found: ", modulePath
        return requireAndPrint moduleMain directory, modulePath

    fn = vm.runInContext (wrap code), (vm.createContext scope), fullPath

    newExports = {}
    newModule = exports:  newExports
    fn(newExports, scopedRequire, newModule, fullPath, directory)
    console.log "newModule: ", newModule

moduleMain = (dir, reference) ->

  # /path/to/app/node_modules
  modulesDir = modulesDirFromFileDir dir
  throw new Error("oj.compile: app directory not found above ${dir}") unless modulesDir?

  # /path/to/app/node_modules/underscore
  moduleDir = path.join modulesDir, reference
  console.log "moduleDir: ", moduleDir
  moduleDirPackage = path.join moduleDir, 'package.json'
  console.log "moduleDirPackage: ", moduleDirPackage
  try
    json = fs.readFileSync moduleDirPackage
    console.log "package: ", json
    main = (JSON.parse json).main
    console.log "main: ", main
    console.log "path.join moduleDir, main: ", path.join moduleDir, main
    return path.join moduleDir, main

  catch e
    throw new Error "oj.compile: package.json not found (#{e})"

isDir = (dir) ->
  try
    stat = fs.statSync dir
    return stat.isDirectory()
  catch e
  false

registerOJExtension = ->
  if require.extensions
    require.extensions['.oj'] = (module, filename) ->
      console.log "registering .oj extension"
      content = compileFile filename
      module._compile content, filename

requireAndPrint = (module) ->
  console.log "requiring: ", module
  require module

cacheModuleDirFromFileDir = {}
modulesDirFromFileDir = (dir) ->
  console.log "modulesDirFromFileDir dir: ", dir
  if cacheModuleDirFromFileDir[dir]?
    console.log "dir found in cache"
    return cacheModuleDirFromFileDir[dir]


  # Navigate up directories until you find node_modules

  appDir = dir
  while true

    console.log "searching #{appDir}"

    # Fail if we are trying to exscape a node_modules directory
    # You can't require stuff passed this barrior
    if (path.basename appDir) == 'node_modules'
      console.log "failure: at node_modules (#{appDir})"
      return null

    # Look in this directory for /<appDir>/node_modules
    modulesDir = path.join appDir, 'node_modules'

    # Success found it
    if isDir modulesDir
      console.log "success: found appDir #{appDir}"
      console.log "success: found modulesDir #{modulesDir}"
      cacheModuleDirFromFileDir[dir] = modulesDir
      return modulesDir

    parentDir = path.dirname appDir

    # Failure we have reached root
    if parentDir == appDir
      console.log "success: at root #{appDir}"

    # Continue searching
    appDir = parentDir

  # Get context
  # context = options.context

  # # Read file
  # # Add oj wrapper
  # # Compile to js if coffee
  # code = ""

  # # oj.compile ojml, options


  # oj.template ojml, options
  # oj.template file, options

  # oj.templateFiles listOfFiles, options

  # output = oj.template options, -> [
  #   'div', css:{width: '5px'}, click: -> console.log('click happened!')
  #     'this is a test'
  # ]

  # output.css = "div.oj28dfez {width: 5px}"
  # output.html = "<div class='oj28dfez'></div>"
  # # output.js = "asdf"

  # output = oj.template file, options, -> [
  #   'div', css:{width: '5px'}, click: -> console.log('click happened!')
  #     'this is a test'
  # ]

  # output.css = "div.oj28dfez {width: 5px}"
  # output.html = "<div class='oj28dfez'></div>"
  # output.js = "$('div.oj28dfez').click(function({console.log('click happened');})"

  # table = oj.Table
  #   ["a", "b"]
  #   ["c", "d"]

  # $('...').oj(table)

  # oj.templateInto element, ojml

watch = (directories, options = {}) ->
  console.log "watch called: (NYI)"
  # oj.compile files, options

error = (message, exitCode = 1) ->
  console.log 'oj: ', message
  process.exit exitCode

success = (message) ->
  error message, 0

isFile = (path) ->
  try
    (fs.statSync path).isFile()
  catch e
    false

isDirectory = (path) ->
  try
    (fs.statSync path).isDirectory()
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
