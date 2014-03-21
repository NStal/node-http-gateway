fs = require "fs"

#http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35
parseRange = (header,size)->
    range = header["range"] or ""
    reg = /^bytes=(\d)?(-)?(\d)?/
    match = range.match reg
    if not match
        return null
    int1 = parseInt(match[1])
    if isNaN(int1)
        int1 = null
    op = match[2]
    int2 = parseInt(match[3])
    if isNaN(int2)
        int2 = null
    if typeof int1 is "number" and op is "-" and typeof int2 is "number"
        # "bytes=500-600"
        return {start:int1,end:int2}
    if typeof int1 is "number" and not op and typeof int2 isnt "number"
        # "bytes=100"
        return {start:0,end:int1-1}
    if typeof int1 is "number" and op is "-" and typeof int2 isnt "number"
        # "bytes=100-"
        return {start:int1,end:size-1}
    if typeof int1 isnt "number" and op is "-" and typeof int2 is "number"
        # "bytes=-600"
        return {start:size-int2,end:size-1}
    return null
        
exports._head = (req,res,option = {},callback)->
    callback = callback or ()->true
    path = option.path or null
    headers = option.headers or {}
    streamCreate = fs.createReadStream.bind(fs)

    if not path
        callback new Error "need a path"
        return
    fs.stat path,(err,stat)->
        if err
            callback err
            return
        if stat.isDirectory()
            callback new Error "is directory"
            return
        range = parseRange req.headers,stat.size
        res.setHeader "Accept-Ranges","bytes"
        ext = require("path").extname(path)
        if exports.Mimes[ext]
            res.setHeader "Content-Type",exports.Mimes[ext]

        for prop of headers
            res.setHeader prop,headers[prop]
        if not range
            res.statusCode = 200
            res.setHeader "Content-Length",stat.size
            callback null,{range:null}
            return
        range.start = range.start or 0
        range.end = range.end or stat.size-1
        if range.end >= stat.size
            range = stat.size -1
        if range.end < range.start
            range.end = stat.size -1
        if range.start > range.end
            range.start = 0
        
        res.statusCode = 206
        res.setHeader "Content-Length",range.end-range.start+1
        res.setHeader "Content-Range","bytes #{range.start}-#{range.end}/#(stat.size)"
        callback null,{range:range}

# via nginx mime.types
exports.Mimes = {
    ".html": "text/html",
    ".htm": "text/html",
    ".shtml": "text/html",
    ".css": "text/css",
    ".xml": "text/xml",
    ".rss": "text/xml",
    ".gif": "image/gif",
    ".jpeg": "image/jpeg",
    ".jpg": "image/jpeg",
    ".js": "application/x-javascript",
    ".atom": "application/atom+xml",
    ".mml": "text/mathml",
    ".txt": "text/plain",
    ".jad": "text/vnd.sun.j2me.app-descriptor",
    ".wml": "text/vnd.wap.wml",
    ".htc": "text/x-component",
    ".png": "image/png",
    ".tif": "image/tiff",
    ".tiff": "image/tiff",
    ".wbmp": "image/vnd.wap.wbmp",
    ".ico": "image/x-icon",
    ".jng": "image/x-jng",
    ".bmp": "image/x-ms-bmp",
    ".svg": "image/svg+xml",
    ".svgz": "image/svg+xml",
    ".jar": "application/java-archive",
    ".war": "application/java-archive",
    ".ear": "application/java-archive",
    ".json": "application/json",
    ".hqx": "application/mac-binhex40",
    ".doc": "application/msword",
    ".pdf": "application/pdf",
    ".ps": "application/postscript",
    ".eps": "application/postscript",
    ".ai": "application/postscript",
    ".rtf": "application/rtf",
    ".xls": "application/vnd.ms-excel",
    ".ppt": "application/vnd.ms-powerpoint",
    ".wmlc": "application/vnd.wap.wmlc",
    ".kml": "application/vnd.google-earth.kml+xml",
    ".kmz": "application/vnd.google-earth.kmz",
    ".7z": "application/x-7z-compressed",
    ".cco": "application/x-cocoa",
    ".jardiff": "application/x-java-archive-diff",
    ".jnlp": "application/x-java-jnlp-file",
    ".run": "application/x-makeself",
    ".pl": "application/x-perl",
    ".pm": "application/x-perl",
    ".prc": "application/x-pilot",
    ".pdb": "application/x-pilot",
    ".rar": "application/x-rar-compressed",
    ".rpm": "application/x-redhat-package-manager",
    ".sea": "application/x-sea",
    ".swf": "application/x-shockwave-flash",
    ".sit": "application/x-stuffit",
    ".tcl": "application/x-tcl",
    ".tk": "application/x-tcl",
    ".der": "application/x-x509-ca-cert",
    ".pem": "application/x-x509-ca-cert",
    ".crt": "application/x-x509-ca-cert",
    ".xpi": "application/x-xpinstall",
    ".xhtml": "application/xhtml+xml",
    ".zip": "application/zip",
    ".bin": "application/octet-stream",
    ".exe": "application/octet-stream",
    ".dll": "application/octet-stream",
    ".deb": "application/octet-stream",
    ".dmg": "application/octet-stream",
    ".eot": "application/octet-stream",
    ".iso": "application/octet-stream",
    ".img": "application/octet-stream",
    ".msi": "application/octet-stream",
    ".msp": "application/octet-stream",
    ".msm": "application/octet-stream",
    ".ogx": "application/ogg",
    ".mid": "audio/midi",
    ".midi": "audio/midi",
    ".kar": "audio/midi",
    ".mpga": "audio/mpeg",
    ".mpega": "audio/mpeg",
    ".mp2": "audio/mpeg",
    ".mp3": "audio/mpeg",
    ".m4a": "audio/mpeg",
    ".oga": "audio/ogg",
    ".ogg": "audio/ogg",
    ".spx": "audio/ogg",
    ".ra": "audio/x-realaudio",
    ".weba": "audio/webm",
    ".3gpp": "video/3gpp",
    ".3gp": "video/3gpp",
    ".mp4": "video/mp4",
    ".mpeg": "video/mpeg",
    ".mpg": "video/mpeg",
    ".mpe": "video/mpeg",
    ".ogv": "video/ogg",
    ".mov": "video/quicktime",
    ".webm": "video/webm",
    ".flv": "video/x-flv",
    ".mng": "video/x-mng",
    ".asx": "video/x-ms-asf",
    ".asf": "video/x-ms-asf",
    ".wmv": "video/x-ms-wmv",
    ".avi": "video/x-msvideo"
}
exports.head = (req,res,option = {},callback = ()->true)->
    exports._head req,res,option,(err)->
        if err
            if err.message is "is directory"
                exports.error 403
                callback error
                return
            
            exports.error404
            callback err
            return
        res.end()
        callback()
exports.get = (req,res,option = {},callback = ()->true)->
    exports._head req,res,option,(err,info)->
        if err
            if err.message is "is directory"
                exports.error 403
                callback error
                return
            
            exports.error404
            callback err
            return
        if info.range
            stream = fs.createReadStream option.path,{start:info.range.start,end:info.range.end}
        else
            stream = fs.createReadStream option.path
        stream.pipe res
        stream.on "error",(err)->
            callback err
        stream.on "end",()->
            callback()
exports.error403 = (req,res)->
    req.statusCode = 403
    res.end()
exports.error404 = (req,res)->
    req.statusCode = 404
    res.end()