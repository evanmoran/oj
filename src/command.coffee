_ = require 'underscore'
commander = require 'commander'
path = require 'path'
fs = require 'fs'
oj = require './oj.js'

module.exports = ->

  commander.version('0.0.3')
    .usage('[options] <file ...>')
    .option('-v, --verbose', 'Turn on verbose output (default: off)')
    .option('-o, --output <dir>', 'Directory to output all files to (default: current)', process.cwd())
    .option('    --output-css <dir>', 'Directory to output css files to (default: current)')
    .option('    --output-js <dir>', 'Directory to output js files to (default: current)')
    .option('    --output-html <dir>', 'Directory to output css files to (default: current)')
    .option('-w, --watch <dir,dir,...>', '(NYI) Directories to watch (default: off)', trimArgList)
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

    appDir = process.cwd()
    for fileName in commander.files
      filePath = path.join appDir, fileName
      console.log "filePath: ", filePath
      error "file not found (#{filePath})" unless isFile filePath

compile = (files, options = {}) ->
  console.log "compile called: ", options
  oj.compile files, options

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
