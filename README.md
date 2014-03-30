# node-http-gateway

To expose internal http/websocket service to external network via authed http/https

# Install
```npm install node-http-gateway```

# Usage
```coffee-script
Gateway = require("node-http-gateway")
Route = Gateway.Route

# if key and cert are provided we use https/wss
# else we use http/ws
gateway = new Gateway({username:"username",password:"password",port:8080,key:"./key.pem",cert:"./cert.pem"})
gateway.addRoute new Route("all","/someone","http://localhost:1080/")
gateway.addRoute new Route("all","/musics","http://localhost:1081/")

gateway.listen()
gateway.on "ready",()=>
    console.log "gateway is running"

# vists http://externalip/someone should proxy to http://localhost:1080/ 
# vists http://externalip/someone/abc should proxy to http://localhost:1080/abc
# same applies to websockets
# etc..
````
