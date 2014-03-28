EventEmitter = require("events").EventEmitter
http = require("http")
https = require("https")
fs = require("fs")
http.globalAgent.maxSockets = 1000
ws = require "ws"
WebSocket = ws
express = require("express")
crypto = require("crypto")
assetPath = require("path").join(__dirname,"../","asset/")
class SafeGateway extends EventEmitter
    constructor:(@config)->
        super()
        @username = @config.username or "gateway"
        @password = @config.password or "miku"
        @routes = []
        @setup()
        @updateToken()
        @onUnauthedRequest = @defaultUnauthedRequestHandler.bind(this)
        @onUnmatchedRequest = @defaultUnmatchedRequestHandler.bind(this)
    genToken:()->
        return crypto.createHash("md5").update(Math.random().toString()).digest("hex")
    updateToken:()->
        @token = @genToken()
    checkAuthCookie:(cookie)->
        if cookie._sgtoken is @token
            return true
        return false
    setup:()->
        @host = @_getExternalIp()
        #todo check port availability
        @port = @config.port or 8899
        if not @host
            @emit "error","No valid external host"
        @app = express()
        if @config.key and @config.cert
            @httpServer = https.createServer({key:fs.readFileSync(@config.key),cert:fs.readFileSync(@config.cert)},@app)
        else
            @httpServer = http.createServer(@app)
        
        @app.use express.cookieParser()
        @bodyParser = express.bodyParser()
        @app.all "*",(req,res)=>
            @check req,(err,state)=>
                if state is true
                    @routeTo req,res
                else
                    @onUnauthedRequest(req,res)
    addRoute:(route)->
        this.routes.push route
    removeRoute:(route)->
        this.router = this.routes.filter (item)->item isnt route
    listen:(callback = ()->)->
        @httpServer.listen @port,@host,(err)=>
            callback(err)
            @emit "ready"
        @websocketServer = new ws.Server({server:@httpServer})
        @websocketServer.on "connection",(connection)=>
            @setupConnection(connection)

    check:(req,callback)->
        if @checkAuthCookie req.cookies
            callback null,true
        else
            callback null,false
    setAuthCookie:(req,res)->
        res.cookie("_sgtoken",@token,)
    defaultUnauthedRequestHandler:(req,res)->
        if req.method.toLowerCase() is "post"
            @bodyParser req,res,()=>
                if req.param("username") is @config.username and req.param("password") is @config.password
                    @setAuthCookie(req,res)
                    res.redirect(req.headers["referer"] or "/")
                    return
                require("node-dynamic").get(req,res,{path:require("path").join(assetPath,"ok.html")})
                return
        else
            require("node-dynamic").get(req,res,{path:require("path").join(assetPath,"login.html")})
        return
    defaultUnmatchedRequestHandler:(req,res)->
        require("node-dynamic").get(req,res,{path:require("path").join(assetPath,"ok.html")})
    routeRequest:(req,res)->
        if not @checkBasicAuthHeader req.headers["authorization"]
            res.status(401)
            res.setHeader "WWW-Authenticate",'Basic realm="your username and password"'
            res.end("Authorization required!")
            return
        if req.cookies.basicAuth isnt req.headers["authorization"]
            res.cookie("basicAuth",req.headers["authorization"])
        @routeTo(req,res)
    routeTo:(req,res)->
        for route in @routes
            if route.match req
                route.handle req,res
                return
        if @onUnmatchedRequest
            @onUnmatchedRequest(req,res);
        else
            res.status(404)
            res.end("not found")
    setupConnection:(connection)->
        req = connection.upgradeReq
        req.path = req.url
        req.method = "websocket"
        cookies = require("cookie").parse(req.headers.cookie or "")
        if not @checkAuthCookie cookies
            connection.close()
            return
        for route in @routes
            if route.match connection.upgradeReq
                route.handleWebSocket connection
                return
        connection.close()
    _getExternalIp:()->
        ip = @config.ip or null
        if ip and ip isnt "auto"
            return ip
        infs = require("os").networkInterfaces()
        for name of infs
            inf = infs[name]
            for address in inf
                if not address.internal and address.family.toLowerCase() is "ipv4"
                    return address.address
        return null

class Route extends EventEmitter
    constructor:(method,@route,@target)->
        @method = method.toLowerCase()
        @proxyTargetObject = require("url").parse(@target)
    match:(req)->
        if @method isnt "all" and @method isnt req.method.toLowerCase()
            return false
        if req.path.indexOf(@route) isnt 0
            return false
        return true
    handleWebSocket:(connection)->
        path = connection.upgradeReq.path
        url = require "url"
        finalPath = url.resolve(@proxyTargetObject.path,path)
        proxyConnection = new WebSocket("ws://#{@proxyTargetObject.host}#{finalPath}")
        _buffers = []
        isOpen = false
        connection.on "error",()=>
            proxyConnection.close();
        connection.on "message",(message)=>
            if isOpen
                proxyConnection.send  message
            else
                _buffers.push message
        proxyConnection.on "open",()=>
            isOpen = true
            for buffer in _buffers
                proxyConnection.send buffer
            proxyConnection.on "message",(message)=>
                connection.send message
        proxyConnection.on "error",()=>
            connection.close()
        proxyConnection.on "close",()=>
            connection.close()
        proxyConnection.on "error",()=>
            connection.close()
        connection.on "close",()=>
            proxyConnection.close()
    handle:(req,res)->
        path = req.path.replace(@route,"")
        method = req.method.toLowerCase()
        url = require "url"
        proxyReq = {
            path:url.resolve(@proxyTargetObject.path,path)
            ,hostname:@proxyTargetObject.hostname
            ,port:@proxyTargetObject.port or 80
            ,method:req.method
            ,headers:req.headers
        }
        _req = http.request proxyReq,(proxyRes)=>
            res.writeHead proxyRes.statusCode,proxyRes.headers
            proxyRes.pipe(res)
        _req.on "error",(err)=>
            res.status(404)
            res.end("error")
        req.pipe _req
module.exports = SafeGateway
module.exports.Route = Route