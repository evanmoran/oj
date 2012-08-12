
#───────────────────────────
# Include
#───────────────────────────

fs = require 'fs'
cp = require 'child_process'
util = require 'util'
_ = require 'underscore'
{spawn, exec} = require 'child_process'
# as = require 'async'

#───────────────────────────
# Utilities
#───────────────────────────

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

#───────────────────────────
# Logging
#───────────────────────────

code =
  red: '\u001b[31m'
  yellow: '\u001b[33m'
  cyan: '\u001b[36m'
  reset: '\u001b[0m'

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

#───────────────────────────
# Tasks
#───────────────────────────

task "build", "Build everything and run tests", ->
  invoke "build:js"
  invoke "build:docs"
  invoke "test"

task "build:js", "Compile coffee script files", ->
  launch 'coffee', ['--compile', 'src/oj.coffee']

task "build:js:watch", "Watch compile coffee script files", ->
  launch 'coffee', ['--compile', '--lint', '-o', 'src', '--watch', 'src']

task "build:docs", "Build documentation", ->
  invoke 'build:groc'

task "build:groc", "Build groc documentation", ->
  launch 'groc', ['--out', 'docs', 'src/*.coffee']

task "build:docco", "Build docco documentation", ->
  launch 'docco', ['src/*.coffee']

task "view:docs", "Open documentation in a browser", ->
  launch 'open', ['docs/oj.html']

task "docs", "Build and view docs", ->
  invoke 'build:docs'
  setTimeout (-> invoke 'view:docs'), 1000

task "test", "Run unit tests", ->
  exec "NODE_ENV=testing mocha", (err, output) ->
    throw err if err
    console.log output

task "test:watch", "Watch unit tests", ->
  launch 'mocha', ['--reporter', 'min', '--watch']
