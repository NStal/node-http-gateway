http = require("http")
fs = require("fs")
pathModule = require("path")
dataString = "0123456789"
filePath = pathModule.join(__dirname,"testFile.txt")
dynamic = require("../")
fs.writeFileSync(filePath,dataString)
callback = ()->true
server = http.createServer (req,res)->
    _callback = callback or ()->
    if req.method.toLowerCase() is "head"
        dynamic.head req,res,{path:filePath,header:{"X-Test":"loremipsum",callback:()->_callback}}
    else if req.method.toLowerCase() is "get"
        dynamic.get req,res,{path:filePath,header:{"X-Test":"loremipsum",callback:()->_callback}}
server.listen(7309)
describe "test full request",()->
    it "test head request",(done)->
        info = {
            hostname:"localhost"
            ,port:7309
            ,method:"head"
            ,path:"/"
        }
        buffers = []
        req = http.request info,(res)->
            console.assert res.headers["content-length"] is "10"
            console.assert res.headers["accept-ranges"] is "bytes"
            console.assert res.headers["content-type"] is "text/plain"
            res.on "data",(data)->
                buffers.push data
            res.on "end",()->
                result = (Buffer.concat buffers).toString()
                console.assert result.length is 0
                done()
                
        req.end()
    it "test get request",(done)->
        info = {
            hostname:"localhost"
            ,port:7309
            ,method:"get"
            ,path:"/"
        }
        buffers = []
        req = http.request info,(res)->
            console.assert res.headers["content-length"] is "10","length"
            console.assert res.headers["accept-ranges"] is "bytes","accept"
            res.on "data",(data)->
                buffers.push data
            res.on "end",()->
                result = (Buffer.concat buffers).toString()
                console.assert result.length is 10,"content length match"
                console.assert result is dataString,"result match"
                done()
                
        req.end()

describe "test partial request",()->
    it "test head request",(done)->
        info = {
            hostname:"localhost"
            ,port:7309
            ,method:"head"
            ,path:"/"
            ,headers:{
                "range":"bytes=1-8"
            }
        }
        buffers = []
        req = http.request info,(res)->
            console.assert res.statusCode is 206,"status code should be 206"
            console.assert res.headers["content-length"] is "8",
            console.assert res.headers["accept-ranges"] is "bytes"
            console.assert res.headers["content-type"] is "text/plain"
            res.on "data",(data)->
                buffers.push data
            res.on "end",()->
                result = (Buffer.concat buffers).toString()
                console.assert result.length is 0
                done()
                
        req.end()
    it "test get request with bytes=1-8",(done)->
        info = {
            hostname:"localhost"
            ,port:7309
            ,method:"get"
            ,path:"/"
            ,headers:{
                "range":"bytes=1-8"
            }
        }
        buffers = []
        req = http.request info,(res)->
            console.assert res.statusCode is 206,"partial with 206"
            console.assert res.headers["content-length"] is "8","length"
            console.assert res.headers["accept-ranges"] is "bytes","accept"
            res.on "data",(data)->
                buffers.push data
            res.on "end",()->
                result = (Buffer.concat buffers).toString()
                console.assert result.length is 8,"content length match"
                console.assert result is dataString.substring(1,9),"result match"
                done()
                
        req.end()
    it "test get request with bytes=-2",(done)->
        info = {
            hostname:"localhost"
            ,port:7309
            ,method:"get"
            ,path:"/"
            ,headers:{
                "range":"bytes=-2"
            }
        }
        buffers = []
        req = http.request info,(res)->
            console.assert res.statusCode is 206,"partial with 206"
            console.assert res.headers["content-length"] is "2","length"
            console.assert res.headers["accept-ranges"] is "bytes","accept"
            res.on "data",(data)->
                buffers.push data
            res.on "end",()->
                result = (Buffer.concat buffers).toString()
                console.assert result.length is 2,"content length match"
                console.assert result is dataString.substring(8),"result match"
                done()
                
        req.end()
    it "test get request with bytes=3",(done)->
        info = {
            hostname:"localhost"
            ,port:7309
            ,method:"get"
            ,path:"/"
            ,headers:{
                "range":"bytes=3"
            }
        }
        buffers = []
        req = http.request info,(res)->
            console.assert res.statusCode is 206,"partial with 206"
            console.assert res.headers["content-length"] is "3","length"
            console.assert res.headers["accept-ranges"] is "bytes","accept"
            res.on "data",(data)->
                buffers.push data
            res.on "end",()->
                result = (Buffer.concat buffers).toString()
                console.assert result.length is 3,"content length match"
                console.assert result is dataString.substring(0,3),"result match"
                done()
        req.end()
        
after (done)->
    fs.unlinkSync filePath
    done()