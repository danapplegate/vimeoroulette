url_module = require 'url'
express = require 'express'
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server);
redis = require 'redis'
vimeoClient = require('vimeo').Vimeo
vimeo = new vimeoClient('1c4c451ed3da57d9a7bb85f4a89529d60e4c836a', 'cff91472ad4e78608e2027f3a4c8dd30cddbbf4f')

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

app.use express.static(__dirname + '/public')
app.use (req, res, next)->
    res.locals =
        title: 'Vimeo Roulette'
    next()

session = {}
app.get '/user/auth', (req, res)->
    url = url_module.parse(req.url, true)
    if url.query.state?
        if url.query.state != 'vimeo_roulette_state'
            res.setHeader('Content-Type', 'text/html')
            res.send 'Error authenticating your user, try again'
            res.send '<a href="' + vimeo.buildAuthorizationEndpoint('http://localhost:3000/user/auth', ['public', 'private'], 'vimeo_roulette_state') + '">Link with Vimeo</a>'
        else
            vimeo.accessToken url.query.code, 'http://localhost:3000/user/auth', (err, token, status, headers)->
                if err
                    res.send "Error: #{err}"
                else
                    if (token.access_token)
                        vimeo.access_token = token.access_token
                        session.user = token.user
                        session.state = "authorized"
                        res.end('User:' + JSON.stringify(session.user))
    else
        res.setHeader('Content-Type', 'text/html')
        res.send '<a href="' + vimeo.buildAuthorizationEndpoint('http://localhost:3000/user/auth', ['public', 'private'], 'vimeo_roulette_state') + '">Link with Vimeo</a>'


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