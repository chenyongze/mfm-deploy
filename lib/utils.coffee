# * 询问是否，接收输入内容
readline = require('readline')
exec = require('child_process').exec
assert = require('assert-plus')
ok = require 'okay'
path = require 'path'
_ = {}
# 接收输入
_.ask_if = (msg, cb)->
    assert.func cb
    rl = readline.createInterface {
        input: process.stdin
        output: process.stdout
    }
    rl.question msg + "(Y/N)? \n", (answer)->
        # 接收输入
        if answer.toLowerCase() is "y"
            rl.close()
            cb(null, true)
            return
        else if answer.toLowerCase() is "n"
            rl.close()
            cb(null, false)
            return
        rl.close()
        _.ask_if msg, (err, a)-> cb(null, a)
# 接收输入
_.ask_if_v = (msg, cb)->
    assert.func cb
    rl = readline.createInterface {
        input: process.stdin
        output: process.stdout
    }
    rl.question msg + "(yes/no)? \n", (answer)->
        # 接收输入
        if answer.toLowerCase() is "yes"
            rl.close()
            cb(null, true)
            return
        else if answer.toLowerCase() is "no"
            rl.close()
            cb(null, false)
            return
        rl.close()
        _.ask_if_v msg, (err, a)-> cb(null, a)

# 询问输入
_.ask_for_input = ( msg,check, cb)->
    assert.func cb
    rl = readline.createInterface {
        input: process.stdin
        output: process.stdout
    }

    rl.question "#{msg}\n", (answer)->
        if not check or check and check(answer)
            rl.close()
            cb(null, answer)
        else
            rl.close()
            ask_for_input(msg, check,cb)

cmd_path = (s)->
    s = JSON.stringify path.normalize s
    s.replace '"',''
    return s
# 执行shell命令
_.work_dir_shell = (arr,cb)->
    assert.func(cb)
    cmd = "sh -c cd " +  cmd_path mfe.path.work_dir
    for v in arr
        cmd += " && " + v
    cmd += ""
    child = exec cmd, (err, stdout, stderr)->
        if err
            cb err
        else
            cb(null)

# 执行shell命令
_.work_dir_shell2 = (arr,cb)->
    assert.func(cb)
    cmd = "cd " + mfe.path.work_dir
    for v in arr
        cmd +=" && " + v
    child = exec cmd, (err, stdout, stderr)->
        if err
            cb err,stdout,stderr
        else
            cb null,stdout,stderr

IS_WIN = process.platform.indexOf('win') is 0

_.escapeReg = (str)->
    str.replace(/[\.\\\+\*\?\[\^\]\$\(\){}=!<>\|:\/]/g, '\\$&')


_.escapeShellCmd = (str)->
    str.replace /\s/g, '"$&"'


_.escapeShellArg = (cmd)->
    return '"' + cmd + '"'

_.isWin = ()-> IS_WIN


_.open = (path, callback)->
    child_process = require 'child_process'
#    console.log 'browse ' + path.yellow.bold '\n'
    cmd = _.escapeShellArg path
    if _.isWin()
        cmd = 'start "" ' + cmd
    else
        if process.env['XDG_SESSION_COOKIE']
            cmd = 'xdg-open ' + cmd
        else if process.env['GNOME_DESKTOP_SESSION_ID']
            cmd = 'gnome-open ' + cmd
        else
            cmd = 'open ' + cmd;
    child_process.exec cmd, callback

module.exports = _

# test
if require.main is module
    _.ask_if "abc", (err, answer)-> console.log(answer)
