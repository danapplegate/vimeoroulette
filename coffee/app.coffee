express = require 'express'
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server);
redis = require 'redis'

io.configure ->
    io.set 'transports', ['xhr-polling']
    io.set 'polling duration', 10

app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'

# Connect to redis server
if process.env.REDISTOGO_URL
    rtg = require('url').parse(process.env.REDISTOGO_URL)
    db = redis.createClient(rtg.port, rtg.hostname)
    db.auth(rtg.auth.split(":")[1])
else
    db = redis.createClient()

app.use express.static(__dirname + '/public')

app.get '/', (req, res) ->
    res.render 'index'

io.sockets.on 'connection', (socket)->
    socket.emit 'news',
        hello: 'world'

app.get '/', (req, res) ->
    res.send req.online.length + ' users online!'

module.exports = server
# delegates user() function
module.exports.use = ->
  app.use.apply app, arguments