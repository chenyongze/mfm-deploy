# * 添加规则到部署标识

fs = require 'fs'
util = require 'util'
DeployBase = require('./DeployBase').DeployBase
walk = require 'walk'

filter_files = (opt, next)->
    files = []

    # Walker options
    walker = walk.walk opt.folder, {
        followLinks: false
    }
    walker.on 'file', (root, stat, next)->
        # Add this file to the list of files
        if opt.filter
            if opt.filter stat
                if opt.map and opt.map.call
                    files.push opt.map stat.name
                else
                    files.push stat.name
        else
            if opt.map and opt.map.call
                files.push opt.map stat.name
            else
                files.push stat.name
        next()
    walker.on 'end', ()->
        next null, files

class DeployList extends DeployBase
    constructor: (cmd,next) ->
        super null,cmd,next
    onDirExists_ : ()->
        filter_files {
            folder: @userDir
            filter: (stat)->
                return stat.name.split(".").pop() is "json"
            map: (name)->
                return name.split(".").shift()
        }, (err, list)=>
            if err
                next err
                return false
            if not list.length
                console.log '还没有创建部署标识,可使用以下命令创建'
                console.log '...................................'
                console.log '   mfm ad <name>'
                console.log '...................................'
            else
                console.log list.join ', '
            @next null
module.exports = {}
module.exports.DeployList = DeployList

