# * 完成模块开发

NameModuleBase = require('./ModuleBase').NameModuleBase

util = require 'util'
fs = require 'fs'
exec = require('child_process').exec
path = require 'path'
_ = require 'underscore'
async = require 'async'
ok = require 'okay'
assert = require 'assert-plus'
utils = require '../utils'


class ModuleComplete extends NameModuleBase
    constructor: (module,cmd,next)->
        super module,cmd,next

    onDirExists_:()->
        async.waterfall [
            @getFolders_.bind(this),
            @getReposStatus_.bind(this),
            @conditionalCommit_.bind(this)
        ],(err)=>
            @next err

    getFolders_ : (cb)->
        assert.func cb
        folders = []
        list = fs.readdirSync mfe.path.work_dir
        pending = list.length
        if not pending then return []
        for name in list
            file = path.join mfe.path.work_dir, name
            stat = fs.statSync file
            if stat.isDirectory()
                if not /^\./i.test name
                    has_dot_git = fs.existsSync "#{file}/.git"
                    if has_dot_git
                        configCnt = fs.readFileSync "#{file}/.git/config", "utf8"
                        # TODO:fixe git url match
                        if /url\s*=\s*git@git\.mofang\.com\:mfe\/.+\.git/im.test configCnt
                            folders.push name
        @folders = folders
        cb()

    conditionalCommit_ : (cb)->
        assert.func cb
        # 是否有其他目录需要提交
        others_need_commit = false
        no_commit = true
        module_need_commit = true
        _.forEach @status,(stat)->
            if stat.module isnt module and not stat.no_modify
                others_need_commit = true
            if not stat.no_modify
                no_commit = false
            if stat.module is module and not stat.no_modify
                module_need_commit = true
        if no_commit
            console.log "没有模块需要提交"
            cb null
            return false
        foldersStatus = []
        if others_need_commit
            if module_need_commit
                utils.ask_if "检查到其他模块有修改，是否一起提交", (err, answer)=>
                    if answer
                        _.forEach @status,(stat)->
                            if not stat.no_modify
                                foldersStatus.push stat
                        @commitFolders_ foldersStatus,cb
                    else
                        _.forEach @status,(stat)->
                            if stat.module is module then foldersStatus.push stat
                        @commitFolders_ [module],cb
            else
                utils.ask_if "[#{module}]模块没有修改,但其他模块有修改，是否提交", (err, answer) =>
                    if answer
                        _.forEach @status,(stat)->
                            if not stat.no_modify
                                foldersStatus.push stat
                        @commitFolders_ @folders,cb
                    else
                        cb null
        else
            _.forEach @status,(stat)->
                if not stat.no_modify
                    foldersStatus.push stat
            @commitFolders_ foldersStatus,cb

    getReposStatus_ : (cb)->
        assert.func cb
        status = []
        async.each @folders,(module,cb)->
            assert.func cb
            cmd_init_git = "cd #{mfe.path.work_dir}
                && cd #{module}
                && git status
                "
            child = exec cmd_init_git, (err, stdout, stderr)->
                stat =
                    module:module
                if err
                    console.log 'exec error: ' + err
                    cb "查询状态失败!"
                else
                    status_no_modify = /nothing\s+to\s+commit/ig.test(stdout) and not /by\s+\d+\s+commit/ig.test(stdout)
                    status_untracked_files = /untracked\s+files/ig.test stdout
                    status_has_uncommit = /changes\s+to\s+be\s*committed/ig.test stdout
                    status_has_push = /by\s+\d+\s+commit/ig.test(stdout) and /use\s+\"git\s+push\"/ig.test(stdout)
                    status_not_staged = /changes\s+not\s+staged/ig.test(stdout) and /use\s+\"git\s+add\"/ig.test(stdout)
                    stat.no_modify = status_no_modify
                    stat.untracked_files = status_untracked_files
                    stat.has_uncommit = status_has_uncommit
                    stat.has_push = status_has_push
                    stat.not_staged = status_not_staged
                    status.push stat
                    cb null
        ,(err)=>
            @status = status
            cb err

    commitFolders_ : (status,next)->
        line = ()->
            # console.log '.......................................'
        async.eachSeries status,(stat,next)->
            after_commit = (next)->
                cmd_commit += " && git pull"
                cmd_commit += " && git push"
                cmd_commit += ""
                line()
                child = exec cmd_commit, (err, stdout, stderr)->
                    console.log stdout
                    line()
                    if err
                        next "shell命令失败!"
                    else
                        next null
            cmd_commit = "cd " + mfe.path.work_dir +
                " && cd " + stat.module
            if stat.untracked_files or stat.not_staged
                cmd_commit += "&& git add -A"
            if stat.has_uncommit or stat.untracked_files or stat.not_staged
                utils.ask_for_input "请输入提交注释:(默认:模块[#{stat.module}]内容修改)",null,(err,answer)->
                    if err
                        next(err)
                        return
                    commit_msg = "模块[#{stat.module}]内容修改"
                    if answer.length then commit_msg = answer
                    cmd_commit += " && git commit -m \"#{commit_msg}\""
                    after_commit next
            else
                after_commit next
        ,next

module.exports = {}
module.exports.ModuleComplete = ModuleComplete

