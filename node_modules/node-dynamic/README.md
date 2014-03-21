# node-dynamic
A module to handle dynamic file with mime and range support. It's useful for media server. Dynamic doesn't mean the file need to be rendered, but it means some steps to be taken before determin which file to be send or just return 404.

When you decide what file to serve by the URI, you can just leave the rest to the node-dynamic. It will handle the mimes, content length, range request etc.


# install
npm install node-dynamic

# test
# install mocha
(sudo) npm install -g mocha
npm test

# example

basic examples 

```javascript
var dynamic = require("node-dynamic");
var decideWhatFileToReturn = function(req){
       return "./file";
}
server = http.createServer(function(req,res){
       //... determine what file to return by req 
       path = decideWhatFileToReturn(req);
       if(req.method.toLowerCase() == "get"){
             dynamic.get req,res,{path:path}
       }else if(req.method.toLowerCase() == "head"){
             dynamic.head req,res,{path:path}
       }else{
             req.statusCode = 404;
             req.end("");
       }
})
server.listen(8080)
```

advanced usage

come latter

