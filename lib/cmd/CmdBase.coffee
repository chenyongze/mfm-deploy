 # * 添加规则到部署标识
fs = require 'fs'
util = require('util')
events = require("events")

class CmdBase extends events.EventEmitter
    constructor: (name,cmd,next) ->
        @name = name
        @cmd = cmd
        @next = next

        @user_conf = mfe.user_conf
        @user = @user_conf.json

        @deployDir = "#{mfe.path.work_dir}/deploy"

module.exports = {}
module.exports.CmdBase = CmdBase

