# * 添加规则到部署标识

util = require 'util'
CmdBase = require('./CmdBase').CmdBase

class Project extends CmdBase
    constructor: (name,cmd,next)->
        super name,cmd,next
        console.log "Project.js not implement"

module.exports.Project = Project

