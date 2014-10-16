fs = require 'fs'
path = require 'path'
fse = require 'fs-extra'
ffs = require 'final-fs'
assert = require 'assert-plus'


defaultIncludes = [
    'tpl'
    'js'
    'css'
    'php'
    'md'
    'txt'
    'sh'
    'html'
    'json'
    'xml'
    'htm'
]

filterExts = (list,exts)->
    r = []
    for f in list
        ext = path.extname f
        ext = ext.substr 1
        if ext in exts
            r.push f
    return r

toUnix = (files,filer ,next)->

    files = filterExts files,filer
    for file in files
        console.log file
        c = fs.readFileSync file ,encoding:"utf-8"
        cnt = c.replace /\r\n/g,"\n"
        err = fs.writeFileSync file ,cnt,encoding:"utf-8"
        if err
            next err
            break

    next null,true

dos2unix = (name,options,next)->
    assert.string name,"name"
    assert.func next, "next"

    options ?= {}
    filter = defaultIncludes
    if options.filter
        if typeof options.filter is "string"
            filter = options.filter.split ","
        else
            filter = options.filter

    p = path.resolve(name);
    if fs.existsSync p
        stat = fs.statSync p
        files = []
        if stat.isFile()
            files.push p
            next toUnix! files,filter
        else if stat.isDirectory()
            console.log p
            o = ffs.readdirRecursive p, true,p
            o.then (files)=>
                next toUnix! files,filter
            o.otherwise (err)=>
                next err
        else
            return next "unknown type."

    else
        next "no a dir or a file :#{name}"
    
module.exports = dos2unix



