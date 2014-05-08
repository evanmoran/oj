// Generated by CoffeeScript 1.6.2
(function() {
  var commander, oj, splitAndTrim, usage, _;

  _ = require('underscore');

  commander = require('commander');

  oj = require('./server');

  module.exports = function() {
    var detectOptionState, options;

    commander.version(oj.version).usage('[options] <file> <dir> ...').option('-m, --minify', 'Turn on minification (default: off)', false).option('-w, --watch', 'Turn on watch mode (default: off)', false).option('-o, --output <dir>', 'Directory to output all files to (default: ./public)', path.join(process.cwd(), 'public')).option('-v, --verbose <level>', 'Turn on verbose level 0-3 (default: 1)', 1).option('-e, --exclude <modules>', 'List of modules to exclude (jquery,oj,...)', splitAndTrim, []).option('--html', 'Include html in the output').option('--css', 'Include css in the output').option('--js', 'Include page js in the output').option('--modules', 'Include modules in output').option('--no-modules', 'Exclude modules in output').option('--all', 'Include all: --html --js --css --modules').option('--modules-dir <dir>', 'Compile files in this dir with --modules (default: ./modules)', './modules').option('--css-dir <dir>', 'Compile files in this dir with --css (default: unset)', null).option('--test', 'For testing purposes log instead of outputing files', false);
    commander.on('--help', function() {
      return console.log("Examples:\n\n  Compile a single file and watch for changes\n\n      oj file_name.oj --watch\n\n  Compile a directory with minification\n\n      oj dirname --minify\n\n  Compile to just html (no js, css or included modules)\n\n      oj file.oj --html\n\n  Compile to just .css file (no js, html or included modules)\n\n      oj file.oj --css\n\n  Compile the included modules to a seperate .js file (no html, css, js)\n\n      oj file.oj --modules\n\n  IMPORTANT:\n\n      OJ can now pre-bundle npm modules together in separate files\n      This support is triggered by adding a `./modules` directory and is\n      auto detected because you almost always want this in a profesional site,\n      as separating unchanging content can drastically speed up page loads times.\n\n  Imagine your page has this structure:\n\n  website/\n    index.oj      (your homepage using OJ!)\n    modules/\n      all.js      (a unifed modules file you will <script> include)\n\n  By adding a `modules/` directory a few things happen automatically:\n\n  1) Files in `modules/*` will be compiled with `--modules` turned on\n\n  2) Files NOT in `modules/*`, will be compiled with `--html --css --js` turned on,\n     which will omit module source from those built files.\n\n  3) Finally, be sure to <script> link your source files to the unified module files\n     Without this the client won't see the shared module code!\n     Specifically, for this example\n\n      * `index.oj` needs a <script src=\"/modules/all.js\"> tag\n\n  For general friendlyness, advice, or feedback come join us on:\n\n    IRC: freenode.net#oj\n\n  To reach out about helping to maintain OJ or advice on creating plugins:\n\n    EMAIL: evan@ojjs.org\n".replace(/^(.*)/gm, "  $1"));
    });
    commander.parse(process.argv);
    detectOptionState = function(option, defaultValue) {
      if (defaultValue == null) {
        defaultValue = null;
      }
      if (process.argv.indexOf('--' + option) !== -1) {
        return true;
      } else if (process.argv.indexOf('--no-' + option) !== -1) {
        return false;
      } else {
        return defaultValue;
      }
    };
    commander.html = detectOptionState('html', null);
    commander.css = detectOptionState('css', null);
    commander.js = detectOptionState('js', null);
    commander.modules = detectOptionState('modules', null);
    commander.test = detectOptionState('test', false);
    if (!_.isArray(commander.args) || commander.args.length === 0) {
      usage();
    }
    options = _.pick(commander, 'args', 'minify', 'output', 'verbose', 'watch', 'exclude', 'all', 'html', 'css', 'js', 'modules', 'modulesDir', 'cssDir', 'test');
    oj.command(options);
  };

  usage = function(code) {
    if (code == null) {
      code = 0;
    }
    commander.help();
    return process.exit(code);
  };

  splitAndTrim = function(str) {
    var o, out, _i, _len, _results;

    out = str.split(',');
    _results = [];
    for (_i = 0, _len = out.length; _i < _len; _i++) {
      o = out[_i];
      _results.push(o.trim());
    }
    return _results;
  };

}).call(this);
