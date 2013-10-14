
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
        .option('-w, --watch', 'Turn on watch mode (default: off)', false)
        .option('-r, --recurse', 'Recurse into directories (default: off)', false)
        .option('-o, --output <dir>', 'Directory to output all files to (default: .)', process.cwd())
        .option('-v, --verbose <level>', 'Turn on verbose level 0-3 (default: 1)', 1)
        .option('-e, --exclude <modules>', 'List of modules to exclude (jquery,oj,...)', splitAndTrim, [])
        # .option('--include [modules]', 'List of modules to include (underscore,backbone,...)', splitAndTrim, [])
        .parse(process.argv)

  No arguments shows usage

      if not _.isArray(commander.args) or commander.args.length == 0
        usage()

      options = _.pick commander, 'args', 'minify', 'output', 'recurse', 'modules', 'verbose', 'watch', 'exclude'

  Execute command through oj module api

      oj.command options
      return

  Helper method to show usage

    usage = (code = 0) ->
      commander.help()
      process.exit code


  Helper method to split lists on comma

    splitAndTrim = (str) ->
      out = str.split(',')
      for o in out
        o.trim()

