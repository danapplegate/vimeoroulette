express = require 'express'
redis = require 'redis'
db = redis.createClient()
app = express()

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