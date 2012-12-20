
# command.coffee
# ==============================================================================

_ = require 'underscore'
commander = require 'commander'
oj = require './server'

module.exports = ->

  commander.version('0.0.5')
    .usage('[options] <file> <dir> ...')
    .option('-d, --debug', 'Turn on debug output (default: false)', false)
    .option('-o, --output <dir>', 'Directory to output all files to (default: .)', process.cwd())
    .option('-r, --recurse', 'Recurse into directories (default: off)', false)
    .option('-m, --modules <modules>', 'List of modules to include', [])
    .option('-v, --verbose <level>', 'Turn on verbose level 0-3 (default: 1)', 1)
    .option('-w, --watch', 'Turn on watch mode (default: off)', false)
    .parse(process.argv)

  # Show usage with no parameters
  if not _.isArray(commander.args) or commander.args.length == 0
    usage()

  options = _.pick commander, 'args', 'debug', 'output', 'recurse', 'modules', 'verbose', 'watch'

  oj.command options
  return

usage = (code = 0) ->
  commander.help()
  process.exit code