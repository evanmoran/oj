path = require 'path'
fs = require 'fs'
{spawn, exec} = require 'child_process'

launch = (cmd, args=[], options, callback = ->) ->

  standardOut = ""
  standardError = ""
  code = 0

  # Options is optional (may be cb instead)
  if _.isFunction options
    callback = options
    options = {}

  callbackAfter = _.after 3, ->
    callback code, standardOut, standardError

  app = spawn cmd, args, options

  if options.console
    app.stdout.pipe process.stdout
    app.stderr.pipe process.stderr

  app.stdout.on 'data', (data) -> standardOut += data.toString()
  app.stderr.on 'data', (data) -> standardError += data.toString()

  app.stdout.on 'end', -> callbackAfter()
  app.stderr.on 'end', -> callbackAfter()
  app.on 'exit', (status) -> callbackAfter()

describe 'oj.command', ->

  it 'exists'#, (done) ->

  #   # console.log "here"
  #   child = exec "oj", (error, stdout, stderr) ->

  #     done()

  #   # launch 'oj', [], (status, stdout, stderr) ->
  #   #   done()

