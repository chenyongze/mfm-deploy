# * 添加规则到部署标识
NameModuleBase = require('./ModuleBase').NameModuleBase
GitManager = require '../GitManager'
gitManager = new GitManager()
ok = require 'okay'
async = require 'async'
assert = require 'assert-plus'

util = require 'util'
fs = require 'fs'
exec = require('child_process').exec
path = require 'path'
_ = require 'underscore'
async = require 'async'
utils = require '../utils'


class ModuleRemove extends NameModuleBase
    constructor:(module,cmd,next)->
        super module,cmd,next

    onDirExists_:()->
        return @next "删除模块【#{@module}】,请谨慎操作！\n  登陆: http://git.mofang.com\n  账户: mfe"

        if @module in ["common","deploy","modules"]
            @next "模块[#{@module}]不能删除"
            return false
        async.waterfall [
            @checkRepos_.bind(this)
            @askToRemove_.bind(this)
            @removeRepos_.bind(this)
            @clearServer_.bind(this)
            @removeLocalDir_.bind(this)
        ],@next

    checkRepos_:(cb)->
        assert.func cb
        gitManager.hasRepos @module, ok cb,(has)=>
            @hasRepos = has
            if has then cb null else cb "模块[#{@module}]不存在"

    askToRemove_:(cb)->
        assert.func cb
        utils.ask_if "确定要删除模块【#{@module}】吗? (删除后无法恢复!请谨慎操作!)",(err,answer)=>
            if answer then cb null else cb "取消删除模块[#{@module}]"

    removeRepos_:(cb)->
        assert.func cb
        gitManager.removeRepos @module, cb

    clearServer_:(cb)->
        assert.func cb
        utils.work_dir_shell [
            "mfe server clean"
            "rm -rf watch.sh"
        ],cb

    removeLocalDir_:(cb)->
        assert.func cb
        utils.work_dir_shell [
            "rm -rf #{@module}"
        ],cb

module.exports = {}
module.exports.ModuleRemove = ModuleRemove
