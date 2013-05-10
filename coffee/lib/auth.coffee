vimeoClient = require('vimeo').Vimeo
vimeo = new vimeoClient('1c4c451ed3da57d9a7bb85f4a89529d60e4c836a', 'cff91472ad4e78608e2027f3a4c8dd30cddbbf4f')

module.exports = (req, res, next)->
    if req.session.state != 'authorized' and req.query.state?
        if req.query.state != 'vimeo_roulette_state'
            res.locals({flash: 'Error authenticating your user, try again'})
        else
            vimeo.accessToken req.query.code, 'http://localhost:3000/user/auth', (err, token, status, headers)->
                if err
                    res.locals({flash: "#{err}"})
                    next()
                else
                    if (token.access_token)
                        vimeo.access_token = token.access_token
                        req.session.user = token.user
                        req.session.state = "authorized"
                        res.redirect '/'
    else
        next()

module.exports.authUrl = vimeo.buildAuthorizationEndpoint('http://localhost:3000/user/auth', ['public', 'private'], 'vimeo_roulette_state')