
###
  Module dependencies.
###

express = require 'express'
http = require 'http'
path = require 'path'
oj = require 'oj'
coffee = require 'coffee-script'

app = express()

# all environments
app.set 'port', process.env.PORT || 3000
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
app.use express.favicon()
app.use express.logger 'dev'
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use require('stylus').middleware __dirname + '/public'
app.use express.static(path.join __dirname, 'public')

# development only
if 'development' == app.get 'env'
  app.use express.errorHandler()

console.log "oj.express: ", oj.express

app.get '/',                require './routes/index'
app.get '/user/:user_id',   require './routes/user'

http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port #{app.get('port')}"
