# * 添加规则到部署标识

exec = require('child_process').exec
util = require 'util'
CmdBase = require('./CmdBase').CmdBase

class Upgrade extends CmdBase
    constructor: (name,cmd,next)->
        super name,cmd,next
        cmd_upgrade = "cd #{mfe.path.cli} npm unlink . && git fetch --all  && git reset --hard origin/master && npm link ."
        child = exec cmd_upgrade, (err, stdout, stderr)->
            if err
                next "git更新仓库失败."
            else
                packageInfo = require "#{mfe.path.cli}/package.json"
                version = packageInfo.version
                next null, version

module.exports = {}
module.exports.Upgrade = Upgrade

