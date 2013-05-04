express = require 'express'
redis = require 'redis'
app = express()
# Connect to redis server
if process.env.REDISTOGO_URL
    rtg = require('url').parse(process.env.REDISTOGO_URL)
    db = redis.createClient(rtg.port, rtg.hostname)
    db.auth(rtg.auth.split(":")[1])
else
    db = redis.createClient()

# Track online users
app.use (req, res, next)->
    db.zadd 'online', Date.now(), req.headers['user-agent'], next

app.use (req, res, next)->
    min = 60 * 1000
    ago = Date.now() - min
    db.zrevrangebyscore 'online', '+inf', ago, (err, users)->
        return next err if err
        req.online = users
        next()

app.get '/', (req, res) ->
    res.send req.online.length + ' users online!'
module.exports = app