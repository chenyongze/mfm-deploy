# * 远程仓库管理器

fs = require "fs"
assert = require 'assert-plus'
utils = require './utils'


class GitManager
    constructor: (args) ->
        instance
        GitManager = ()-> return instance
        GitManager.prototype = @
        instance = new GitManager()
        instance.constructor = GitManager
        return instance

    # 根据名称生成git 仓库的地址
    getUrlByName_ : (module)->
        return "/Users/lynn/server/#{module}.git"

    # 判断远程是否存在该仓库
    hasRepos : (module, cb)->
        assert.func cb
        url = @getUrlByName_ module
        has = false
        if fs.existsSync url
            has = true
        cb null, has

    # 添加一个名为initRepos的仓库
    initRepos : (module, cb)->
        assert.func cb
        url = @getUrlByName_ module
        if fs.existsSync url
            cb null, url
            return
        else
            utils.work_dir_shell [
                "mkdir -p #{url}",
                "cd #{url}",
                "git init --bare"
            ],(err)->
                cb err,url

    # 删除名为module的仓库
    removeRepos : (module, cb)->
        assert.func cb
        url = @getUrlByName_ module
        if fs.existsSync url
            utils.work_dir_shell [
                "rm -rf #{url}",
            ],cb
            return
        else
            cb null

    # 获取仓库列表
    getModuleNames : (cb)->
        utils.work_dir_shell2 [
            "cd /Users/lynn/server"
            "ls -all"
        ],(err,out)->
            names = out.match /\s(\w+)\.git/g
            list = []
            list.push name.replace(/\.git/,"").replace(/(^\s+)|(\s+$)/g,"") for name in names
            cb null,list

    # 添加用户user到名称为gitName的仓库
    getList : (user, gitName, cb)->
        assert.func cb
        cb(null)

    # 根据模块名获取远程仓库地址
    getUrlByModuleName : (module, cb)->
        assert.func cb
        url = @getUrlByName_ module
        cb null, url

    # 根据名称返回对应的url
    getUrlsByModuleNames : (modules, cb)->
        assert.func cb
        list = []
        for module in modules
            url = "/Users/lynn/server/#{module}.git"
            if not fs.existsSync url
                cb "附加模块 [#{module}] 不存在"
                return false
            list.push {
                module: module
                url: url
            }
        cb null, list
        return true
module.exports =  GitManager
