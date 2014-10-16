# * json文件数据存储

fs = require "fs"

class JsonStore
    json : null
    isNew : null
    constructor: (filename)->
        @filename = filename
        @reload()
    reload : ()->
        exist = fs.existsSync @filename
        if !exist
            @json = {}
            @isNew = true
        else
            @json = require @filename
            @isNew = false
    save : ()->
        fs.writeFileSync @filename, JSON.stringify(@json), {
            encoding: "utf8"
        }

if require.main is module
    conf = new JsonStore './test/cna.json'
    conf.json.def = "abc"
    conf.save()
else
    module.exports = JsonStore
