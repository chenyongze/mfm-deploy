# * 准备目录结构
ModuleBase = require('./ModuleBase').ModuleBase
colors   = require 'colors'

util = require 'util'
assert = require 'assert-plus'
_ = require "underscore"
ok = require 'okay'
async = require 'async'
shell = require 'shelljs'
fs = require 'fs'
exec = require('child_process').exec

utils = require '../utils'
GitManager = require '../GitManager'
gitManager = new GitManager()
path = require 'path'

work_dir_shell = utils.work_dir_shell

sleep = (time,fn)->
    setTimeout fn,time

# 询问是否创建该模块
ask_create = (module, cb)->
    utils.ask_if "是否创建[#{module}]业务模块", (err,answer)-> cb err,answer

# 部署默认目录
release_defaults = (cb)->
    work_dir_shell [
        "mfe server clean"
    ],cb

# 检出一个仓库
checkoutRepos = (module, url, cb)->
    assert.func cb
    cmds = [
        "rm -rf #{module}"
        "git clone #{url} #{module}"
    ]
    work_dir_shell cmds,cb

class ModulePrepareDirectory extends ModuleBase
    addUser:(gitname,cb)->
        #TODO:CACHE error E0001
        #-------------------------------
        # if not @user.addedRepos or not @user.addedRepos.length
        #     @user.addedRepos = []
        for projectName in @user.addedRepos
            if projectName is gitname
                cb()
                return
        # add project name in user
        err,success = gitManager.addUserToRepos! @user.username,gitname
        if success
            # save project name in user data cache
            @user.addedRepos.push gitname
            @user_conf.save();
        cb err,success
    constructor: (module,cmd,next)->
        super module,cmd,next

        err,out = exec! "sh -c pwd"
        if err
            next err
            return false
        if out and out.length
            out = out.replace /\s+/,""
        exists = fs.existsSync "#{out}/deploy"
        existsGit = fs.existsSync "#{out}/deploy/.git"
        if not exists and not existsGit
            err,answer = utils.ask_if_v! "警告:将清除目录【#{out}】下所有文件,要继续吗".red
            if err
                next err
                return false
            if not answer
                next "请更换目录"
                return false
        assert.func next
        @defaultModules = mfe.defaultModules

        # todo: E0001 evety time init a cache array
        @user.addedRepos = []

        async.waterfall [
            @clearDir_.bind(this),
            @checkoutDeploy_.bind(this),
            @templatesServerConfig_.bind(this),
            @checkoutDefaultModules_.bind(this),
            @checkoutAddModules_.bind(this),
            @initMainModule_.bind(this),
            @initDeploys_.bind(this),
            @prepareComplete.bind(this),
        ],next
    # 创建模块
    createModule_ : (module, cb)->
        assert.func cb
        gitManager.initRepos module, ok cb,(url)=>
            sleep !1000
            @addUser! module
            # 复制文件夹到模块
            shell.rm '-rf', "#{mfe.path.work_dir}/#{module}"
            shell.cp '-rf', "#{mfe.path.templates}/module", mfe.path.work_dir
            cmds =[
                "mv module #{module}"
                "cd #{module}"
                "git init && git add -A "
                "git commit -m \"first commit\""
                "git remote add origin #{url}"
                "git push -u origin master"
            ]
            work_dir_shell cmds,cb
    # 切换到模块
    startModule_ : (module, cb)->
        assert.func cb
        # 获取远程仓库地址
        gitManager.getUrlByModuleName module, ok cb,(url)=>
            @addUser! module
            # 删除当前目录
            shell.rm '-rf',"#{mfe.path.work_dir}/#{module}"
            # 拉取远程仓库
            work_dir_shell ["git clone #{url} #{module}"],cb

    # 1.清空文件夹
    clearDir_ : (cb)->
        work_dir_shell [
            "rm -rf *"
            "rm -rf *.*"
        ],cb

    # 2.deploy仓库
    checkoutDeploy_:(cb)->
        gitManager.getUrlByModuleName "deploy", ok cb,(url)=>
            # 拉取默认仓库
            @addUser! 'deploy'
            checkoutRepos "deploy", url, cb

    # ++.模板服务器相关设置
    templatesServerConfig_:(cb)->
        cb()

    # 3.拉取默认模块
    checkoutDefaultModules_ : (cb)->
        assert.func cb
        async.each mfe.defaultModules,(module, cb)=>
            gitManager.hasRepos module, ok cb,(has)=>
                # 如果不存在，创建该项目后，初始化默认文件
                if not has
                    gitManager.initRepos module, ok cb,(url)=>
                        @addUser ! module
                        cmds = [
                            "mkdir #{module}"
                            "cd #{module}"
                            "touch README.md"
                            "git init"
                            "git add -A "
                            "git commit -m \"first commit\""
                            "git remote add origin #{url}"
                            "git push -u origin master "
                        ]
                        work_dir_shell cmds,cb
                # 如果存在该项目，则拉取该项目
                else
                    gitManager.getUrlByModuleName module, ok cb,(url)=>
                        # 拉取默认仓库
                        @addUser! module
                        checkoutRepos module, url, cb
        ,cb
    # 4.拉取附加模块
    checkoutAddModules_ : (cb)->
        assert.func cb
        modules = @cmd.add
        # 如果附加模块指定了默认模块，提示退出
        for m in @defaultModules
            if _.contains modules,m
                cb "模块[#{m}]是默认模块,不用额外指定!"
                return
        # 如果指定附加模块,拉取附加模块
        if modules and modules.length
            # 获取git仓库的urls
            gitManager.getUrlsByModuleNames modules, ok cb,(list)=>
                # TODO:xxxxxxxxxxx
                @addUser! modules
                cmds = []
                for o in list
                    cmds.push "git clone #{o.url} #{o.module}"
                work_dir_shell cmds,cb
        else
            cb()
    # 新建的git仓库添加默认文件
    createDefaultFiles_ : (module, cb)->
        assert.func cb
        cmds =[
            "touch README.md"
            "git add -A"
            "git commit -m \"auto init add readme file\""
            "git push -u origin master"
        ]
        work_dir_shell cmds,cb
    # 5.初始化主模块
    initMainModule_ : (cb)->
        assert.func cb
        # 检查服务器是否存在该git仓库?
        gitManager.hasRepos @module, ok cb,(has)=>
            # 不存在:
            if not has
                ask_create @module, ok cb,(create)=>
                    if create
                        @createModule_ @module, cb
                    else
                        cb "业务模块不存在"
            # 存在:取回默认模块,检查当前模块内文件完整性,watch制定模块,提示可用
            else
                @startModule_ @module,cb
    # 6.初始化各个模块的部署文件
    initDeploys_ : (cb)->
        assert.func cb
        if not @cmd.deploy or @cmd.deploy is "local"
            deployName = '""'
        else
            if @cmd.deploy.indexOf "/" is -1
                @username = @user.username
            else
                @username = @cmd.deploy.split("/")[0]
                @cmd.deploy = @cmd.deploy.split("/")[1]
            deployName = JSON.stringify path.normalize "#{mfe.path.work_dir}/deploy/#{@username}/#{@cmd.deploy}.json"

        template = """/* fis-conf.js 由mfm工具自动生成,请勿手动修改 */
         var fs = require('fs')
         conf.init(__dirname);
         if( fs.existsSync( __dirname + "/pack.js")){
             require( __dirname + "/pack.js");
         }
         """
        template2 = """
         conf.parseDeploy({filename:**deploy**});
         //new conf.ModuleConfig();
         new conf.**config**();
        """
        modules = []
        modules.push module for module in mfe.defaultModules
        if @cmd.add then modules.push module for module in @cmd.add
        modules.push @module
        writeFile = (filename,name,conf)->
            content = template + template2.replace("**deploy**",name).replace("**config**",conf)
            fs.writeFileSync filename,content
        for module in modules
            filename = "#{mfe.path.work_dir}/#{module}/fis-conf.js"
            if module is "common"
                writeFile filename,deployName,"ModuleConfig"
            else if module is "modules"
                writeFile filename,deployName,"ModuleConfig"
            else if module is "mfe"
                content = """
                /* fis-conf.js 由mfm工具自动生成,请勿手动修改 */
                """
                fs.writeFileSync filename,content
            else
                writeFile filename,deployName,"ModuleConfig"
        cb null
    # 7.准备完成
    prepareComplete : (cb)->
        throw new Error "abstract method!"

module.exports = {}
module.exports.ModulePrepareDirectory = ModulePrepareDirectory
