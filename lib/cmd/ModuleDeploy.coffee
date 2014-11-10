# * 部署业务模块
ModulePrepareDirectory = require('./ModulePrepareDirectory').ModulePrepareDirectory

util = require 'util'
assert = require 'assert-plus'
fs = require 'fs'
request = require 'request'

utils = require '../utils'


class ModuleDeploy extends ModulePrepareDirectory

    # ++.模板服务器设置
    templatesServerConfig_:(cb)->
        # 如果没有设置部署标识则部署到模板服务器
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
    "receiver_statics": "",
    "output_statics": "qiniu",
    "output_statics": "../aaaaa",
    "receiver_templates": "http://templates.mofang.com/receiver.php",
    "output_templates": "channel/#{channelId}",
    "name": "templates_server"
}
    """
            deployFilename = "#{work_dir}/deploy/#{uname}/templates_server.json"
            fs.writeFileSync deployFilename,deployContent

            # 提示正在使用模板服务器
            if @cmd.channel
                console.log "\n正在使用模板服务器，通道:【#{channelId}】\n"

            # 如果设置清除通道模板则发送请求更新服务器模板
            if not @cmd.cleanup
                cb()
                return true
            error, response, body = request! "http://templates.mofang.com/api/clean_channel.php?channel=#{channelId}"
            if error
                console.log "cleanup error:#{error}"
                process.exit()
            if response.statusCode isnt 200
                console.log "templates server response code:#{response.statusCode}"
                process.exit()
            if body isnt "0"
                console.log "remove folder error,response code:#{body}"
                process.exit()
            if body is "0"
                console.log "清空通道#{channelId}部署完成."
                cb()
            else
                console.log "moduleDeploy.js:unknown error."
                process.exit()
        else
            cb()

    # .目录结构完整后，部署模块
    prepareComplete : (cb)->
        assert.func cb

        # 必须指定部署标识
        if not @cmd.deploy then return cb "部署标识未指定 -d <name>"

        # 不可同时发布到线上和模板包
        if @cmd.online and @cmd.package
            return @next "不能同事使用--online 和--package参数"

        # 如果带有--online 或 --package 则必须指定通道编号
        if @cmd.online or @cmd.package
            if not @cmd.channel
                return @next "请填写要部署到的通道编号:例如12"

        # 再次确认部署该模块
        if @cmd.online
            err,answer = utils.ask_if_v! "直接上线:将要通过模板服务器将模块【#{@module}】及相关资源直接到线上,请确认操作".green
        else if @cmd.package
            err,answer = utils.ask_if_v! "与代码同步上线:将打包模块【#{@module}】及相关资源到线上,并生成模板部署id,请确认操作".yellow
        else if @cmd.deploy is "templates_server"
            err,answer = utils.ask_if_v! "将要以上线标准部署模块【#{@module}】到模板服务器,以便通过模板服务器预览线上效果,请确认操作".blue
        else
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

        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 发送打包命里,返回模板包id
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        if @cmd.package
            uname = mfe.user_conf.json.username
            channelId = if @cmd.channel is true then uname else "#{uname}_#{@cmd.channel}"
            error, response, body = request! "http://templates.mofang.com/api/package_pre_release.php?channel=#{channelId}"
            if error
                console.log "package templates error: #{error}"
                process.exit()
            if response.statusCode isnt 200
                console.log "package templates response code: #{response.statusCode}"
                process.exit()
            response = JSON.parse body
            if response.code
                if response.error
                   console.log "package templates error: #{response.error}"
            else
                console.log "package templates error: unknown"
                process.exit()
                console.log "\n模板ID: #{response.data}\n"
                fs.writeFileSync 'template_id.txt',"#{response.data}\n"

        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # 发送上线命令,返回自增版本
        #+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        # mfm dm common -c 12 -o
        if @cmd.online
            uname = mfe.user_conf.json.username
            channelId = if @cmd.channel is true then uname else "#{uname}_#{@cmd.channel}"
            error, response, body = request! "http://templates.mofang.com/api/package_release.php?channel=#{channelId}"
            if error
                console.log "release package error: #{error}"
                process.exit()
            if response.statusCode isnt 200
                console.log "release package error: #{response.statusCode}"
                process.exit()
	    try
		response = JSON.parse body
	    catch error
		console.log response.body
            if response.code
                if response.error
                    console.log "release package error: #{response.error}"
		else
		    console.log "release package error: unknown"
		    process.exit()
            console.log "\n模板版本: #{response.data}\n"
            fs.writeFileSync 'templates_version.txt',"#{response.data}\n"
        #process.exit() # debug
        #err,out = utils.work_dir_shell2! cmds
        #fs.writeFileSync 'v.log',out
        cb null

module.exports = {}
module.exports.ModuleDeploy = ModuleDeploy
