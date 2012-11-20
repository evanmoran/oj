# Includer magic that makes oj delicious
path = require 'path'
fs = require 'fs'

module.exports = includer = (directory) ->
  console.log "includer called with directory:", directory
  (reference) ->
    console.log "include called with reference:", reference
    console.log "directory: ", directory

    fullPath = path.resolve reference
    console.log "fullPath: ", fullPath

    try
      file = fs.readFileSync fullPath, 'utf8'
      console.log "file: ", file
    catch e
      console.log "e: ", e


