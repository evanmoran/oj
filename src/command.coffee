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

  for filePath in commander.files
    require path.join process.cwd(), filePath

watch = (directories, options = {}) ->
  console.log "watch called: (NYI)"

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
