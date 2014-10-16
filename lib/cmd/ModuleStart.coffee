# * 添加规则到部署标识
ModulePrepareDirectory = require('./ModulePrepareDirectory').ModulePrepareDirectory

util = require 'util'
assert = require 'assert-plus'
fs = require 'fs'

utils = require '../utils'

work_dir_shell = utils.work_dir_shell

class ModuleStart extends ModulePrepareDirectory
    # ++.模板服务器设置
    templatesServerConfig_:(cb)->
        # 如果有--channel参数则使用模板服务器方式
        if @cmd.channel
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
    "domain": "http://templates.mofang.com/channel/#{channelId}",
    "receiver_statics": "http://templates.mofang.com/receiver.php",
    "output_statics": "channel/#{channelId}",
    "receiver_templates": "http://templates.mofang.com/receiver.php",
    "output_templates": "channel/#{channelId}",
    "name": "templates_server"
}
"""
            deployFilename = "#{work_dir}/deploy/#{uname}/templates_server.json"
            fs.writeFileSync deployFilename,deployContent
        cb()

    # .目录结构完整后，部署模块
    prepareComplete : (cb)->
        assert.func cb
        # 清除服务器
        err = work_dir_shell! ["mfe server clean"]
        if err then return cb err
        cmds = []
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 部署 mfe(本地smarty) 支撑文件
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 没有设置部署，也没有设置强制推送，则部署mfe到指定位置
        if not @cmd.deploy and not @cmd.mfe
            cmd = "mfe release -r mfe"
            if @cmd.optimize
                cmd += " -#{@cmd.optimize}"
            cmds.push cmd

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
                cmds.push cmd

        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 部署 主模块
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        main_cmd = "mfe release -w -r #{@module}"
        if @cmd.deploy
            main_cmd += " -d #{@cmd.deploy}_statics,#{@cmd.deploy}_templates"
        if @cmd.optimize
            main_cmd += " -#{@cmd.optimize}"
        cmds.push main_cmd

        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 生成脚本文件
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        content = """
        #{cmds.join "\n"}

        """
        filename = "#{mfe.path.work_dir}/watch.sh"
        fs.writeFileSync filename,content
        fs.chmodSync filename,"777"

        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 打印帮助信息
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        console.log ""
        console.log "++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++"
        console.log " 当前业务模块【#{@module}】                   "
        console.log "++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++"
        console.log "+   按Ctrl + C 退出                     +"
        console.log "+   退出后,可以手动运行以下命令:        +"
        console.log "+       ./watch.sh                      +"
        console.log "++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++"

        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 执行部署脚本
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        work_dir_shell cmds,cb

module.exports = {}
module.exports.ModuleStart = ModuleStart
