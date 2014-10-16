# * 添加规则到部署标识

fs = require 'fs'
util = require 'util'
NameBaseDeploy = require('./DeployBase').NameBaseDeploy
inquirer = require "inquirer"
assert = require "assert-plus"
JsonStore = require "../JsonStore"

class AskQuestion
    constructor: (edit,store,cb)->
        assert.func cb
        o =  store.json
         # 设置域名
        q =
            name : "domain"
            message : "设置域名"
        if edit then q.message += ":[#{o.domain}]"
        q.validate = (domain)->
            domain = domain or o.domain
            if not domain or not domain.length
                return true
            else
                if domain is "null"
                    return true
                if not /^http\:\/\//.test domain
                    return "域名url不合法"
                return true
            return true
         # 静态文件接收网址
        q1 =
            name : "receiver_statics"
            message : "静态文件接收网址"
        if edit then q1.message += ":[#{o.receiver_statics}]"
        q1.validate = (receiver)->
            receiver = receiver or o.receiver_statics
            if not receiver or not receiver.length
                return true
            else
                if receiver is "null" then return true
                if not /^http\:\/\//.test receiver
                    return "您输入的url不合法"
                return true
            return true
        # 静态文件保存路径
        q11 =
            name : "output_statics"
            message : "静态文件保存路径"
        if edit then q11.message += ":[#{o.output_statics}]"
        q11.validate = (output)->
            output = output or o.output_statics
            if not output or not output.length
                return false
            return true

        # 模板文件接收网址
        q2 =
            name : "receiver_templates"
            message : "模板文件接收网址"
        if edit then q2.message += ":[#{o.receiver_templates}]"
        q2.validate = (receiver)->
            receiver = receiver or o.receiver_templates
            if not receiver or not receiver.length
                return true
            else
                if receiver is "null" then return true
                if not /^http\:\/\//.test receiver
                    return "您输入的url不合法"
                return true
            return true
        # 模板保存路径
        q21 =
            name : "output_templates"
            message : "模板保存路径"
        if edit then q21.message += ":[#{o.output_templates}]"
        q21.validate = (output)->
            output = output or o.output_templates
            if not output or not output.length
                return false
            return true
        inquirer.prompt [ q, q1 ,q11,q2,q21], ( answers )->
            if o.domain and  not answers.domain
                answers.domain = o.domain
            if o.receiver_statics and  not answers.receiver_statics
                answers.receiver_statics = o.receiver_statics
            if o.output_statics and  not answers.output_statics
                answers.output_statics = o.output_statics
            if o.receiver_templates and not answers.receiver_templates
                answers.receiver_templates = o.receiver_templates
            if o.output_templates and not answers.output_templates
                answers.output_templates = o.output_templates
            if answers.receiver_statics is 'null'
                answers.receiver_statics = null
            if answers.receiver_templates is 'null'
                answers.receiver_templates  = null
            if answers.domain is 'null'
                answers.domain  = null
            store.json.domain = answers.domain
            store.json.receiver_statics = answers.receiver_statics
            store.json.output_statics = answers.output_statics
            store.json.receiver_templates = answers.receiver_templates
            store.json.output_templates = answers.output_templates
            cb null,answers

class DeployAdd extends NameBaseDeploy
    constructor: (name,cmd,next)->
        super name,cmd,next
    onFileExists_ : ()->
        @next "部署标识[#{@name}]已经存在"

    onFileNotExists_ : ()->
        store = new JsonStore @filename
        new AskQuestion false,store,(err,answers)=>
            store.json.name = @name
            store.save()
            @commitChanges_ "add deploy [#{@name}]",@next

module.exports = {}
module.exports.DeployAdd = DeployAdd
module.exports.AskQuestion = AskQuestion

