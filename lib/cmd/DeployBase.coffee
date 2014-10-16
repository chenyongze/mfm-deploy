# * 添加规则到部署标识
fs = require 'fs'
util = require 'util'
CmdBase = require('./CmdBase').CmdBase
assert = require 'assert-plus'
utils = require '../utils'

class DeployBase extends CmdBase
    constructor: (name,cmd,next)->
        super name,cmd,next
        if cmd.user
            @username = cmd.user
        else
            @username = @user.username
        @userDir = "#{@deployDir}/#{@username}"

        fs.exists @deployDir,(exists)=>
            if not exists then next "非工作目录，请先初始化工作目录 mfm sm <module>"
            else @updateGit_()
    updateGit_ : (cb)->
        if not fs.existsSync @userDir
            fs.mkdirSync @userDir
        @onDirExists_()
    onDirExists_ : ()->
    commitChanges_ : (msg,cb)->
        assert.func cb
        utils.work_dir_shell2 [
            "cd deploy"
            "git add -A"
            "git commit -m \"#{msg}\""
            "git pull --rebase"
            "git push"
        ],(err,out)=>
            if err and out.match /nothing\sto\scommit/gi
                cb "部署[#{@name}]无任何修改"
            else
                cb err

class NameBaseDeploy extends DeployBase
    constructor: (name,cmd,next)->
        super name,cmd,next
        @name = name
        if @name.indexOf("/") isnt -1
            @username = @name.split("/")[0]
            @userDir = "#{@deployDir}/#{@username}"
            if not fs.existsSync @userDir
                fs.mkdirSync @userDir
        @filename = "#{@deployDir}/#{@username}/#{@name}.json"

    onDirExists_ :()->
        super
        fs.exists @filename,(exists)=> if not exists then @onFileNotExists_() else @onFileExists_()
    onFileNotExists_ : ()-> @next "部署标识[#{@name}]不存在"
    onFileExists_ : ()->

module.exports = {}
module.exports.CmdBase = CmdBase
module.exports.DeployBase = DeployBase
module.exports.NameBaseDeploy = NameBaseDeploy

