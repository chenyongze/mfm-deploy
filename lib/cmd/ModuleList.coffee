# * 添加规则到部署标识
NameModuleBase = require('./ModuleBase').NameModuleBase
GitManager = require '../GitManager'
gitManager = new GitManager()
ok = require 'okay'
assert = require 'assert-plus'

async = require 'async'
utils = require '../utils'


class ModuleList extends NameModuleBase
    constructor:(module,cmd,next)->
        super module,cmd,next
    onDirExists_:()->
        gitManager.getModuleNames (err,names)=>
            console.log names.join " , "
            @next
module.exports = {}
module.exports.ModuleList = ModuleList
