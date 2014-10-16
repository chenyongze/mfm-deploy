# * 添加规则到部署标识

fs = require 'fs'
util = require 'util'
NameBaseDeploy = require('./DeployBase').NameBaseDeploy
path = require "path"

class DeployRemove extends NameBaseDeploy
    constructor: (name,cmd,next)->
        super name,cmd,next
    onFileExists_ : ()->
        fs.unlinkSync @filename
        this.commitChanges_ "remove deploy [#{@name}]",@next
        # check user dir is empty
        dirname = path.dirname @filename
        try
            fs.rmdirSync dirname
        catch
            111
module.exports = {}
module.exports.DeployRemove = DeployRemove

