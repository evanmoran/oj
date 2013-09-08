
# Include
# ------------------------------------------------------------------------------

fs = require 'fs'
cp = require 'child_process'
util = require 'util'
_ = require 'underscore'
{spawn, exec} = require 'child_process'
path = require 'path'
async = require 'async'
crypto = require 'crypto'
http = require 'http'
https = require 'https'
uglify = require 'uglify-js'

# Paths
# ------------------------------------------------------------------------------

CAKE_DIR = __dirname
ROOT_DIR = path.join CAKE_DIR, '..'
WWW_DIR = path.join CAKE_DIR, 'www'
WWW_DOWNLOAD_DIR = path.join CAKE_DIR, 'www', 'download'
WWW_SCRIPTS_DIR = path.join CAKE_DIR, 'www', 'scripts'
PAGES_DIR = path.join CAKE_DIR, 'pages'
GENERATED_DIR = path.join CAKE_DIR, 'generated'
VERSIONS_DIR = path.join CAKE_DIR, 'versions'
DOCS_DIR = path.join CAKE_DIR, 'docs'
SRC_DIR = path.join CAKE_DIR, 'src'
GIT_DIR = path.join CAKE_DIR, '..'

# Version Data
# ------------------------------------------------------------------------------

LIBS =
  'oj':
    packageDir:path.join ROOT_DIR, 'oj'
    inputFile:path.join GENERATED_DIR, 'oj.js'
    removeFirstLine: true
    copyrightName: 'Evan Moran'
    docsUrl:'ojjs.org'
    outputDirs: [
      VERSIONS_DIR
      path.join WWW_DOWNLOAD_DIR, 'oj'
    ]
  'oj.AceEditor':
    packageDir:path.join ROOT_DIR, 'oj.AceEditor'
    docsUrl:'ojjs.org/plugins#AceEditor'
    outputDirs: [
      path.join WWW_DOWNLOAD_DIR, 'oj.AceEditor'
    ]
  'oj.GitHubButton':
    packageDir:path.join ROOT_DIR, 'oj.GitHubButton'
    docsUrl:'ojjs.org/plugins#GitHubButton'
    outputDirs: [
      path.join WWW_DOWNLOAD_DIR, 'oj.GitHubButton'
    ]
  'oj.TwitterButton':
    packageDir:path.join ROOT_DIR, 'oj.TwitterButton'
    docsUrl:'ojjs.org/plugins#TwitterButton'
    outputDirs: [
      path.join WWW_DOWNLOAD_DIR, 'oj.TwitterButton'
    ]
  'oj.VimeoVideo':
    packageDir:path.join ROOT_DIR, 'oj.VimeoVideo'
    docsUrl:'ojjs.org/plugins#VimeoVideo'
    outputDirs: [
      path.join WWW_DOWNLOAD_DIR, 'oj.VimeoVideo'
    ]
  'oj.YouTubeVideo':
    packageDir:path.join ROOT_DIR, 'oj.YouTubeVideo'
    docsUrl:'ojjs.org/plugins#YouTubeVideo'
    outputDirs: [
      path.join WWW_DOWNLOAD_DIR, 'oj.YouTubeVideo'
    ]
  'oj.JSFiddle':
    packageDir:path.join ROOT_DIR, 'oj.JSFiddle'
    docsUrl:'ojjs.org/plugins#JSFiddle'
    outputDirs: [
      path.join WWW_DOWNLOAD_DIR, 'oj.JSFiddle'
    ]
  'oj.markdown':
    packageDir:path.join ROOT_DIR, 'oj.markdown'
    docsUrl:'ojjs.org/plugins#markdown'
    outputDirs: [
      path.join WWW_DOWNLOAD_DIR, 'oj.markdown'
    ]
  'oj.mustache':
    packageDir:path.join ROOT_DIR, 'oj.mustache'
    docsUrl:'ojjs.org/plugins#mustache'
    outputDirs: [
      path.join WWW_DOWNLOAD_DIR, 'oj.mustache'
    ]


# Tasks
# ------------------------------------------------------------------------------

task "all", "Build everthing: compile, copy, version, and tests", ->
  invoke "build:js"
  invoke "build:docs"
  invoke "version:libs"
  invoke "copy:examples"
  invoke "test"

task "build", "Build everything", ->
  invoke "build:js"
  invoke "build:docs"
  invoke "version:libs"

task "build:js", "Compile coffee script files", ->
  launch 'coffee', ['--compile', '-o', GENERATED_DIR, 'src/oj.litcoffee']
  launch 'coffee', ['--compile', '-o', GENERATED_DIR, 'src/server.litcoffee']
  launch 'coffee', ['--compile', '-o', GENERATED_DIR, 'src/command.litcoffee']

task "build:js:watch", "Watch coffee script files", ->
  launch 'coffee', ['--compile', '--watch', '-o', GENERATED_DIR, 'src/oj.litcoffee']
  launch 'coffee', ['--compile', '--watch', '-o', GENERATED_DIR, 'src/server.litcoffee']
  launch 'coffee', ['--compile', '--watch', '-o', GENERATED_DIR, 'src/command.litcoffee']

  # For convenience update the site scripts/oj.js to force try editor to latest version of oj
  launch 'coffee', ['--compile', '--watch', '-o', WWW_SCRIPTS_DIR, 'src/oj.litcoffee']

# Version, minify, prepend license comment, and output to multiple directories
versionAndMinifyLib = (libName, libData) ->

  # Load package.json for lib
  json = require(path.join libData.packageDir, 'package.json')

  # Calculate minified name
  libData.fileName ?= (libName + '.js')
  libData.minifiedFileName = append unappend(libName,'.js'), '.min.js'

  libData.version = json.version
  libData.copyrightName ?= 'Evan Moran'

  # Default values
  libData.inputFile ?= path.join libData.packageDir, json.main
  libData.licenseUrl ?= 'ojjs.org/license'
  libData.copyrightName ?= 'Evan Moran'

  # Load code from file
  libData.code = loadSync libData.inputFile

  # Remove first line if necessary (coffee-script generated)
  if libData.removeFirstLine
    libData.code = removeFirstLine libData.code

  # Minify code
  libData.minifiedCode = uglify libData.code

  # Add release and minified release comments
  releaseText = """
    //
    // #{libData.fileName} v#{libData.version}
    // #{libData.docsUrl}
    //
    // Copyright 2013, #{libData.copyrightName}
    // Released under the MIT License
    //\n
  """
  minfiedReleaseText = """
    // #{libData.minifiedFileName} v#{libData.version} | Copyright 2013 #{libData.copyrightName} | #{libData.licenseUrl}\n
  """

  libData.code = releaseText + libData.code
  libData.minifiedCode = minfiedReleaseText + libData.minifiedCode

  # Save to www/script directory
  outputPath = path.join WWW_SCRIPTS_DIR, libData.fileName
  info 'Saving ' + outputPath
  saveSync outputPath, libData.code

  # Save to output directories
  for outputDir in libData.outputDirs
    # Save latest/<name>.js
    outputPath = path.join outputDir, 'latest', libData.fileName
    info 'Saving ' + outputPath
    saveSync outputPath, libData.code

    # Save latest/<name>.min.js
    outputPath = path.join outputDir, 'latest', libData.minifiedFileName
    info 'Saving ' + outputPath
    saveSync outputPath, libData.minifiedCode

    # Save <version>/<name>.js
    outputPath = path.join outputDir, libData.version, libData.fileName
    info 'Saving ' + outputPath
    saveSync outputPath, libData.code

    # Save <version>/<name>.min.js
    outputPath = path.join outputDir, libData.version, libData.minifiedFileName
    info 'Saving ' + outputPath
    saveSync outputPath, libData.minifiedCode

task "version:libs", "All release text, minifiy and copy oj and plugins", ->

  for libName, libData of LIBS
    versionAndMinifyLib libName, libData

task "copy:examples", "Copy example projects to www", ->
  info 'Copying examples'
  launch 'rsync', ['-a', path.join(ROOT_DIR,'oj-examples/'), path.join(WWW_DIR, 'examples/')]

task "ddd", "Build debug www", ->
  launch 'oj', ['--recurse', '--verbose', '2', '--exclude', 'jquery', '--output', WWW_DIR, PAGES_DIR]

task "ddd:watch", "Watch debug www", ->
  launch 'oj', ['--recurse', '--watch', '--verbose', '2', '--exclude', 'jquery', '--output', WWW_DIR, PAGES_DIR]

task "www", "Build www", ->
  launch 'oj', ['--recurse', '--minify', '--verbose', '2', '--exclude', 'jquery', '--output', WWW_DIR, PAGES_DIR]

task "www:watch", "Watch build www", ->
  launch 'oj', ['--recurse', '--minify', '--watch', '--verbose', '2', '--exclude', 'jquery', '--output', WWW_DIR, PAGES_DIR]

task "watch", "Watch all build targets", ->
  invoke 'build:js:watch'

task "build:docs", "Build documentation", ->
  launch 'docco', [SRC_DIR + '/oj.litcoffee', '--output', DOCS_DIR]
  launch 'docco', [SRC_DIR + '/server.litcoffee', '--output', DOCS_DIR]
  launch 'docco', [SRC_DIR + '/command.litcoffee', '--output', DOCS_DIR]

task "view:docs", "Open documentation in a browser", ->
  launch 'open', ['docs/oj.html']

# task "docs", "Build and view docs", ->
#   invoke 'build:docs'
#   setTimeout (-> invoke 'view:docs'), 1000

task "test", "Run unit tests", ->
  exec "NODE_ENV=testing mocha", (err, output) ->
    throw err if err
    console.log output

task "test:watch", "Watch unit tests", ->
  launch 'mocha', ['--reporter', 'min', '--watch']

_modules =
  jquery: 'http://code.jquery.com/jquery-2.0.3.min.js',
  assert: 'https://raw.github.com/joyent/node/master/lib/assert.js',
  console: 'https://raw.github.com/joyent/node/master/lib/console.js',
  crypto: 'https://raw.github.com/joyent/node/master/lib/crypto.js',
  events: 'https://raw.github.com/joyent/node/master/lib/events.js',
  freelist: 'https://raw.github.com/joyent/node/master/lib/freelist.js',
  punycode: 'https://raw.github.com/joyent/node/master/lib/punycode.js',
  querystring: 'https://raw.github.com/joyent/node/master/lib/querystring.js'
  string_decoder: 'https://raw.github.com/joyent/node/master/lib/string_decoder.js',
  url: 'https://raw.github.com/joyent/node/master/lib/url.js',
  util: 'https://raw.github.com/joyent/node/master/lib/util.js',
  tty: 'https://raw.github.com/gist/2649813/01789078ef19464e8065416a3e95661f4c71b52f/tty.js'
  # Overriding path to remove util dependency
  # path: 'https://raw.github.com/joyent/node/master/lib/path.js',
task 'list', 'list node modules', ->
  console.log _.keys _modules

# Download all the built in node module files
task 'download', 'download node modules', ->
  moduleDir = path.join __dirname, 'modules'
  for module, url of _modules
    do (module, url) ->
      filepath = path.join moduleDir, "#{module}.js"

      console.log 'downloading: ', url
      download url, (err, data) ->
        console.log "downloaded: #{url} (#{data.length} characters)"

        minifiedData = uglify data
        console.log "minified: #{url} (#{minifiedData.length} characters)"

        console.log "saving: #{filepath} (#{minifiedData.length} characters)"
        save filepath, minifiedData, (err) ->
          throw err if err

# Utilities
# ------------------------------------------------------------------------------

optionsMode = (options, modes = ['production', 'staging', 'testing', 'development']) ->
  optionsCombine options, modes

optionsCombine = (options, choices) ->
  for choice in choices
    if options[choice]
      break
  choice

captialize = (str) ->
  "#{str.charAt(0).toUpperCase()}#{str.slice(1)}"

# envFromObject({FOO:'bar', FOO2:'bar2'}) => 'FOO=bar FOO2=bar2 '
envFromObject = (obj) ->
  out = ""
  for k,v of obj
    out += "#{k}=#{v} "
  out

# download: download the url to string
download = (url, cb) ->
  httpx = if startsWith(url, 'https:') then https else http
  options = require('url').parse url
  data = ""
  req = httpx.request options, (res) ->
    res.setEncoding "utf8"
    res.on "data", (chunk) ->
      data += chunk
    res.on "end", ->
      cb null, data, url
  req.end()

# Determine if string starts with other string
startsWith = (strInput, strStart) ->
  throw 'startsWith: argument error' unless (_.isString strInput) and (_.isString strStart)
  strInput.length >= strStart.length and strInput.lastIndexOf(strStart, 0) == 0

# Determine if string starts with other string
endsWith = (strInput, strEnd) ->
  throw 'endsWith: argument error' unless (_.isString strInput) and (_.isString strEnd)
  strInput.length >= strEnd.length and strInput.lastIndexOf(strEnd, strInput.length - strEnd.length) == strInput.length - strEnd.length

# Remove first line in string
removeFirstLine = (str) ->
  endOfFirstLine = str.indexOf('\n') + 1
  str.slice endOfFirstLine

# Prepend string if necessary
prepend = (strInput, strStart) ->
  if (_.isString strInput) and (_.isString strStart) and not (startsWith strInput, strStart)
    return strStart + strInput
  strInput

# Prepend string if necessary
unprepend = (strInput, strStart) ->
  if _.isString(strInput) && _.isString(strStart) && startsWith(strInput, strStart)
    return strInput.slice strStart.length
  strInput

# Append string if necessary
append = (strInput, strEnd) ->
  if (_.isString strInput) and (_.isString strEnd) and not (endsWith strInput, strEnd)
    return strInput + strEnd
  strInput

# Unappend string if necessary
unappend = (strInput, strEnd) ->
  if _.isString(strInput) && _.isString(strEnd) && endsWith(strInput, strEnd)
    return strInput.slice 0, strInput.length - strEnd.length
  strInput

# mkdir: make a directory if it doesn't exist (mkdir -p)
mkdir = (dir, cb) ->
  fs.stat dir, (err, stats) ->
    if err?.code == 'ENOENT'
      fs.mkdir dir, cb
    else if stats.isDirectory
      cb(null)
    else
      throw "mkdir: #{dir} is not a directory"
      cb({code:"NotDir"})

# mkdirSync: make a directory syncronized if it doesn't exist (mkdir -p)
# Returns true if a new directory has been created but didn't exist before
mkdirSync = (dir) ->
  try
    stats = fs.statSync dir
    if not stats.isDirectory
      throw "mkdirSync: non-directory exists in location specified (#{dir})"
  catch err
    if err?.code == 'ENOENT'
      fs.mkdirSync dir
      return true
  false

# save: save file to path
save = (filepath, data, cb) ->
  cb ?= ->
  dir = path.dirname filepath
  # Ensure directory exists
  mkdir dir, (err) ->
    # Write file into directory
    fs.writeFile filepath, data, cb

# save: save file to path
saveSync = (filepath, data) ->

  dir = path.dirname filepath

  # Ensure directory exists
  mkdirSync dir

  # Write file into directory
  fs.writeFileSync filepath, data

# load: load a file into a string
load = (filepath, cb) ->
  fs.readFile filepath, "utf8", cb

# loadSync: load file into a string synchronously
loadSync = (filepath) ->
  fs.readFileSync filepath, "utf8"

# Logging
# ------------------------------------------------------------------------------

code =
  reset: '\u001b[0m'
  black: '\u001b[30m'
  red: '\u001b[31m'
  green: '\u001b[32m'
  yellow: '\u001b[33m'
  blue: '\u001b[34m'
  magenta: '\u001b[35m'
  cyan: '\u001b[36m'
  gray: '\u001b[37m'

log = (message, color, explanation) -> console.log code[color] + message + code.reset + ' ' + (explanation or '')
error = (message, explanation) -> log message, 'red', explanation
info = (message, explanation) -> log message, 'cyan', explanation
warn = (message, explanation) -> log message, 'yellow', explanation

launch = (cmd, args=[], options, callback = ->) ->
  # Options is optional (may be cb instead)
  if _.isFunction options
    callback = options
    options = {}

  # Info output command being run
  info "[#{envFromObject options?.env}#{cmd} #{args.join ' '}]"

  # cmd = which(cmd) if which
  app = spawn cmd, args, options
  app.stdout.pipe(process.stdout)
  app.stderr.pipe(process.stderr)
  app.on 'exit', (status) -> callback() if status is 0
