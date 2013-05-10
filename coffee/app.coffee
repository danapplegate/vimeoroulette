url_module = require 'url'
express = require 'express'
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
redis = require 'redis'
auth = require './lib/auth'

io.configure ->
    io.set 'transports', ['xhr-polling']
    io.set 'polling duration', 10

app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'

# Connect to redis server
if process.env.REDISTOGO_URL
    rtg = url_module.parse(process.env.REDISTOGO_URL)
    db = redis.createClient(rtg.port, rtg.hostname)
    db.auth(rtg.auth.split(":")[1])
else
    db = redis.createClient()
    pub = redis.createClient()

app.use express.logger()
app.use express.static(__dirname + '/public')
app.use express.cookieParser('se#ret$auc3')
app.use express.cookieSession({ secret: 'c0oki3$ecgeT' })
app.use (req, res, next)->
    res.locals
        title: 'Vimeo Roulette'
        flash: false
    next()
app.use (req, res, next)->
    res.locals({user: JSON.stringify(req.session.user) if req.session.state == 'authorized'})
    next()

app.get '/user/auth', auth, (req, res)->
    res.redirect '/' if req.session.state == 'authorized'
    res.render 'auth',
        authUrl: auth.authUrl

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

module.exports = server
# delegates use() function
module.exports.use = ->
  app.use.apply app, arguments