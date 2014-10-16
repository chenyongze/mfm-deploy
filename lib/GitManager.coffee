if off
    GitManager = require './GitManagerLocal'
else
    GitManager = require './GitManagerImpl'
module.exports =  GitManager
