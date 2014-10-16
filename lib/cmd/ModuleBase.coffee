# 模块命令基类
#
fs = require 'fs'
util = require 'util'
CmdBase = require('./CmdBase').CmdBase

class ModuleBase extends CmdBase
    constructor: (module,cmd,next)->
        super null,cmd,next
        @module = module

class NameModuleBase extends ModuleBase
    constructor: (module,cmd,next)->
        super module,cmd,next
        exists = fs.existsSync @deployDir
        if not exists
            next "非工作目录，请先初始化工作目录 mfm sm <module>"
        else
            @onDirExists_()
    onDirExists_ : ()->
    commitChanges_ : (msg,cb)->
        console.log msg
        cb(null)

module.exports = {}
module.exports.ModuleBase = ModuleBase
module.exports.NameModuleBase = NameModuleBase

