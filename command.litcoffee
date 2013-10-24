
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
        .option('-o, --output <dir>', 'Directory to output all files to (default: ./www)', path.join process.cwd(), 'www')
        .option('-v, --verbose <level>', 'Turn on verbose level 0-3 (default: 1)', 1)
        .option('-e, --exclude <modules>', 'List of modules to exclude (jquery,oj,...)', splitAndTrim, [])
        # .option('--include [modules]', 'List of modules to include (underscore,backbone,...)', splitAndTrim, [])

        .option('--all', 'Include all content: --html --css --js --modules (default: on)', true)
        .option('--html', 'Include html in the output (default: off)', false)
        .option('--css', 'Include css in the output (default: off)', false)
        .option('--js', 'Include page js in the output (default: off)', false)
        .option('--modules', 'Include modules js in output(default: off)', false)
        .option('--no-modules', 'Include all but modules js: --html --css --js (default: off)', false)

        .option('--modules-dir <dir>', 'Compile files in this dir with --modules (default: ./modules)', path.join process.cwd(), 'modules')
        .option('--css-dir <dir>', 'Compile files in this dir with --css (default: unset)', null)
        .parse(process.argv)

  No arguments shows usage

      if not _.isArray(commander.args) or commander.args.length == 0
        usage()

      options = _.pick commander, 'args', 'minify', 'output', 'modules', 'verbose', 'watch', 'exclude', 'html', 'css', 'js', 'modules', 'noModules', 'modulesDir', 'cssDir'

      options.recurse = !commander.noRecurse

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

