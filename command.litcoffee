
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
        .option('-m, --minify', 'Turn on minification (default: off)', false)
        .option('-w, --watch', 'Turn on watch mode (default: off)', false)
        .option('-o, --output <dir>', 'Directory to output all files to (default: ./public)', path.join process.cwd(), 'public')
        .option('-v, --verbose <level>', 'Turn on verbose level 0-3 (default: 1)', 1)
        .option('-e, --exclude <modules>', 'List of modules to exclude (jquery,oj,...)', splitAndTrim, [])
        # .option('--include [modules]', 'List of modules to include (underscore,backbone,...)', splitAndTrim, [])

        .option('--html', 'Include html in the output')
        .option('--css', 'Include css in the output')
        .option('--js', 'Include page js in the output')
        .option('--modules', 'Include modules in output')
        .option('--no-modules', 'Exclude modules in output')
        .option('--all', 'Include all: --html --js --css --modules')

        .option('--modules-dir <dir>', 'Compile files in this dir with --modules (default: ./modules)', './modules')
        .option('--css-dir <dir>', 'Compile files in this dir with --css (default: unset)', null)

        .option('--test', 'For testing purposes log instead of outputing files', false)

  Custom help

      commander.on '--help', ->
        console.log """
          Examples:

            Compile a single file and watch for changes

                oj file_name.oj --watch

            Compile a directory with minification

                oj dirname --minify

            Compile to just html (no js, css or included modules)

                oj file.oj --html

            Compile to just .css file (no js, html or included modules)

                oj file.oj --css

            Compile the included modules to a seperate .js file (no html, css, js)

                oj file.oj --modules

            IMPORTANT:

                OJ can now pre-bundle npm modules together in separate files
                This support is triggered by adding a `./modules` directory and is
                auto detected because you almost always want this in a profesional site,
                as separating unchanging content can drastically speed up page loads times.

            Imagine your page has this structure:

            website/
              index.oj      (your homepage using OJ!)
              modules/
                all.js      (a unifed modules file you will <script> include)

            By adding a `modules/` directory a few things happen automatically:

            1) Files in `modules/*` will be compiled with `--modules` turned on

            2) Files NOT in `modules/*`, will be compiled with `--html --css --js` turned on,
               which will omit module source from those built files.

            3) Finally, be sure to <script> link your source files to the unified module files
               Without this the client won't see the shared module code!
               Specifically, for this example

                * `index.oj` needs a <script src="/modules/all.js"> tag

            For general friendlyness, advice, or feedback come join us on:

              IRC: freenode.net#oj

            To reach out about helping to maintain OJ or advice on creating plugins:

              EMAIL: evan@ojjs.org

        """.replace(/^(.*)/gm, "  $1") # indent with 2 spaces

  Parse args and run command

      commander.parse(process.argv)

  Hand parse boolean arguments because Commander default behavior is strange

      detectOptionState = (option, defaultValue = null) ->

  `--option` means true

        if process.argv.indexOf('--' + option) != -1
          true

  `--no-option` means false

        else if process.argv.indexOf('--no-' + option) != -1
          false
        else
          defaultValue

  Parse them manually

      commander.html = detectOptionState 'html', null
      commander.css = detectOptionState 'css', null
      commander.js = detectOptionState 'js', null
      commander.modules = detectOptionState 'modules', null
      commander.test = detectOptionState 'test', false

  No arguments shows usage

      if not _.isArray(commander.args) or commander.args.length == 0
        usage()

      options = _.pick commander, 'args', 'minify', 'output', 'verbose', 'watch', 'exclude', 'all', 'html', 'css', 'js', 'modules', 'modulesDir', 'cssDir', 'test'

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

