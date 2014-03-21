SafeGateway = require("../")
Route = SafeGateway.Route
sg = new SafeGateway({username:"test",password:"test",port:7999,ip:"127.0.0.1",key:"key.pem",cert:"cert.pem"})
sg.addRoute new Route("all","/nginx","http://localhost:80/")
sg.addRoute new Route("all","/sybil","http://localhost:3006/")
sg.on "ready",()=>
    console.log "ready"
sg.listen()
