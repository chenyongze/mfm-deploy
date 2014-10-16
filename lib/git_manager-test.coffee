# * 远程仓库管理器
exec = require('child_process').exec
gitHand = require("../test")
assert =require('assert-plus')

fs = require("fs")

class GitManager
    constructor: () ->
    # 根据名称生成git 仓库的地址
    getUrlByName_ = (module,fun)->
        assert.func fun
        gitHand.createRepos module,(projects)->
            fun projects
            console.log(projects.web_url)
    # 判断远程是否存在该仓库
    hasRepos : (module, cb)->
        assert.func cb
        @getModuleNames (projects)->
            flag= false
            for project in projects
                if project.name is module
                    flag = true
                    break
            flag and console.log("仓库存在") or console.log("仓库不存在")
    # 添加一个名为initRepos的仓库
    initRepos : (module, cb)->

    # 获取仓库列表
    GitManager.prototype.getModuleNames = (fun)->
        assert.func fun
        gitHand.showProject null,(projects)->
            fun projects

    # 添加用户user到名称为gitName的仓库
    getList = (pro,user, gitName, cb)->
        # 查询用户获取用户ID&&gitID
        createUser = user
        projectId = pro
        @getModuleNames (projects)->
            for project in projects
                if project.name is pro
                    console.log project.id
        gitHand.showUsers null,(user)->
            if user.name is createUser
                console.log(user.id)
                return
                # gitHand.addUser()

    # 根据模块名获取远程仓库地址
    getUrlByModuleName : (module, cb)->
        assert.func cb
        url = this.getUrlByName_ module
        cb null, url

    # 根据名称返回对应的url
    getUrlsByModuleNames : (modules, cb)->
        assert.func cb
        list = []
        for module in modules
            url = "/Users/lynn/server/#{module}.git"
            if not fs.existsSync(url)
                cb "附加模块 [#{module}] 不存在"
                return false
            list.push {
                module: module
                url: url
            }
        cb null, list

if require.main is module
    gitInfo = new GitManager()
    gitInfo.getList("baozi","zhaoshuai")


