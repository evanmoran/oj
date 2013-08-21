
command.coffee
==============================================================================

  Dependencies

    _ = require 'underscore'
    commander = require 'commander'
    oj = require './server'

    module.exports = ->

  Usage

      commander.version(oj.version)
        .usage('[options] <file> <dir> ...')
        .option('-m, --minify', 'Turn on minification (default: false)', false)
        .option('-o, --output <dir>', 'Directory to output all files to (default: .)', process.cwd())
        .option('-r, --recurse', 'Recurse into directories (default: off)', false)
        .option('-v, --verbose <level>', 'Turn on verbose level 0-3 (default: 1)', 1)
        .option('-w, --watch', 'Turn on watch mode (default: off)', false)
        # .option('--modules <modules>', 'List of modules to include', [])
        .parse(process.argv)

  No arguments shows usage

      if not _.isArray(commander.args) or commander.args.length == 0
        usage()

      options = _.pick commander, 'args', 'minify', 'output', 'recurse', 'modules', 'verbose', 'watch'

  Execute command through oj module api

      oj.command options
      return

  Helper method to show usage

    usage = (code = 0) ->
      commander.help()
      process.exit code