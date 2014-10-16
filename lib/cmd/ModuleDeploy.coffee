# * 部署业务模块
ModulePrepareDirectory = require('./ModulePrepareDirectory').ModulePrepareDirectory

util = require 'util'
assert = require 'assert-plus'
fs = require 'fs'

utils = require '../utils'

class ModuleDeploy extends ModulePrepareDirectory

    # ++.模板服务器设置
    templatesServerConfig_:(cb)->
        # 如果有--channel参数则使用模板服务器方式
        if not @cmd.deploy
            # 添加部署规则
            @cmd.deploy = "templates_server"
            # 添加优化参数
            if @cmd.optimize and @cmd.optimize.indexOf "D" isnt -1
                @cmd.optimize = "D#{@cmd.optimize}"
            else
                @cmd.optimize = "D"
            # 生成模板服务器的部署文件
            work_dir = mfe.path.work_dir
            uname = mfe.user_conf.json.username
            channelId = if @cmd.channel is true then uname else "#{uname}_#{@cmd.channel}"
            deployContent = """
{
    "domain": "http://sts0.mofang.com",
    "receiver_statics": "http://qiniu",
    "output_statics": "qiniu",
    "receiver_templates": "http://templates.mofang.com/receiver.php",
    "output_templates": "release",
    "name": "templates_server"
}
"""
            deployFilename = "#{work_dir}/deploy/#{uname}/templates_server.json"
            fs.writeFileSync deployFilename,deployContent
        cb()

    # .目录结构完整后，部署模块
    prepareComplete : (cb)->
        assert.func cb

        # 必须指定部署标识
        if not @cmd.deploy then return cb "部署标识未指定 -d <name>"

        # 再次确认部署该模块
        err,answer = utils.ask_if_v! "警告:将要以【#{@cmd.deploy}】规则,部署模块【#{@module}】及相关资源到线上,模块和部署标识是否正确".red
        if not answer then return @next "模块【#{@module}】的部署操作取消"

        cmds = []

        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 部署 modules common 模块
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        for moduleName in mfe.defaultModules
            if @module isnt moduleName and moduleName isnt "mfe"
                cmd = "mfe release -r #{moduleName}"
                if @cmd.deploy
                    cmd += " -d #{@cmd.deploy}_statics,#{@cmd.deploy}_templates"
                if @cmd.optimize
                    cmd += " -#{@cmd.optimize}"
                    cmd += " --verbose"
                cmd += " -moDup"
                cmds.push cmd

        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 部署 主模块
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        main_cmd = "mfe release -r #{@module}"
        if @cmd.deploy
            main_cmd += " -d #{@cmd.deploy}_statics,#{@cmd.deploy}_templates"
        if @cmd.optimize
            main_cmd += " -#{@cmd.optimize}"
            main_cmd += " --verbose"
        main_cmd += " -moDup"
        cmds.push main_cmd

        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 生成脚本文件
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        content = """
        #{cmds.join "\n"}

        """
        filename = "#{mfe.path.work_dir}/release.sh"
        fs.writeFileSync filename,content
        fs.chmodSync filename,"777"


        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 执行部署脚本
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        err,out = utils.work_dir_shell2! cmds
        fs.writeFileSync 'v.log',out
        cb null

module.exports = {}
module.exports.ModuleDeploy = ModuleDeploy
