# * 添加规则到部署标识

exec = require('child_process').exec
inquirer = require "inquirer"

module.exports = (next)->
    err,response = exec! "git config --get --global user.name"
    gitname = null
    if not err
        gitname = response.replace /\s+/g,""
    q = "请输入GitLab用户名"
    if gitname then q = "#{q}:[#{gitname}]"
    inquirer.prompt [{
        name:"username"
        message:q
        validate:(username)->
            if not username or not username.length
                if gitname
                    return true
                else
                    return "请输入GitLab用户名"
            if username.length < 3
                return "用户名长度不小于三位"
            return true
    }], ( answers )->
        if not answers.username and gitname
            answers.username = gitname
        mfe.user_conf.reload()
        mfe.user_conf.json.username = answers.username
        mfe.user_conf.json.init = true
        mfe.user_conf.save()