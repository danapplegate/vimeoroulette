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
    pub = redis.createClient()

app.use express.static(__dirname + '/public')
app.use (req, res, next)->
    res.locals =
        title: 'Vimeo Roulette'
    next()

app.get '/room/:id', (req, res)->
    res.render 'room',
        room_id: req.params.id

app.get '/', (req, res) ->
    res.render 'index'

io.sockets.on 'connection', (socket)->
    pub.publish 'users', 'A new user has joined!'
    db.on 'message', (channel, message)->
        socket.emit 'news', channel + ': ' + message
    db.subscribe 'users'

    socket.on 'disconnect', ->
        pub.publish 'users', 'A user has left'
        db.unsubscribe 'users'

app.get '/', (req, res) ->
    res.send req.online.length + ' users online!'

module.exports = server
# delegates user() function
module.exports.use = ->
  app.use.apply app, arguments