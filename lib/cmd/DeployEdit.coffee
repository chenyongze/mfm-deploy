#
# 修改部署规则

fs = require 'fs'
util = require 'util'
NameBaseDeploy = require('./DeployBase').NameBaseDeploy
AskQuestion = require('./DeployAdd').AskQuestion
JsonStore = require "../JsonStore"

class DeployEdit extends NameBaseDeploy
    constructor: (name,cmd,next) ->
        super name,cmd,next
    onFileExists_:->
        store = new JsonStore @filename
        new AskQuestion true,store,(err,answers)=>
            store.json.name = @name
            store.save()
            @commitChanges_ "edit deploy #{@name}",@next

module.exports = {}
module.exports.DeployEdit = DeployEdit

