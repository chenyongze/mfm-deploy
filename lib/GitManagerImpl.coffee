#  远程仓库管理器

fs = require "fs"
assert = require 'assert-plus'
utils = require './utils'
Gitlab = require("gitlab").ApiV3
Cache = require './Cache'

# http://git.mofang.com
credentials = {
  host: "http://git.mofang.com"
  hostname: "git.mofang.com"
  token: "nsC6ioUEVfAdTKBzpStH"
  password: "mofang888"
  login: "mfe@mofang.com"
  user: "mfe"
}

sleep = (time,fn)->
    setTimeout fn,time

class GitManager

    constructor: (args) ->
        instance
        @gitlab = new Gitlab {
            token: credentials.token
            url: credentials.host
            password: credentials.password
            login: credentials.login
        }
        @email = credentials.login
        @cache = new Cache
        @usePrefix_ = off

        GitManager = ()-> return instance
        GitManager.prototype = @
        instance = new GitManager()
        instance.constructor = GitManager
        return instance

    prefix : "mfm-"
    name : (name) ->
        if @usePrefix_ then @prefix + name else name

    getProjects_ : (cb) ->
        assert.func cb
        if @cache.get "projects"
            cb @cache.get 'projects'
            return yes
        all  = @gitlab.projects.all!
        projects = []
        for project in all
            if project.owner.email is @email
                if @usePrefix_
                    if project.name.match /^mfm-/i
                        projects.push project
                else
                    projects.push project
        @cache.set 'projects',projects,4
        cb @cache.get 'projects'

    getUsers_ : (cb) ->
        assert.func cb
        if @cache.get "users"
            cb @cache.get 'users'
            return yes
        all  = @gitlab.users.all! {per_page:1000}
        users = []
        for user in all
            users.push user
        @cache.set 'users',users,20
        cb @cache.get 'users'

    # 判断远程是否存在该仓库
    hasRepos : (module, cb)->
        assert.string module
        assert.func cb
        if not module.length
            cb 'module name must set'
            return false
        projects = @getProjects_!
        has = no
        for project in projects
            if project.name is @name(module)
                has = yes
        cb null, has

    # 添加一个名为module的仓库
    initRepos : (module, cb)->
        assert.func cb
        err,has = @hasRepos! module
        if has
            projects= @getProjects_!
            url = null
            if not projects
                cb null,""
                return false
            for project in projects
                if project.name is @name module
                    url = project.ssh_url_to_repo
            cb null,url
        else
            name = @name module
            project = @gitlab.projects.create! {name:name}
            if project and project.ssh_url_to_repo
                @cache.clear 'projects'
                sleep! 1000
                cb null,project.ssh_url_to_repo

    # 删除名为module的仓库
    # TODO: DELETE method not support by nginx
    removeRepos : (module, cb)->
        http = require 'http'
        id = encodeURIComponent "#{credentials.user}/#{module}"

        options = {
            hostname: '192.168.1.110'
            port: 80
            path: "/api/v3/projects/#{id}?private_token=#{credentials.token}"
            method: 'DELETE'
        }
        console.log options.path
        req = http.request options, (res)->
            res.setEncoding('utf8');
            console.log "statusCode: ", res.statusCode
            console.log "headers: ", res.headers
            res.on 'data',  (chunk)->
                console.log chunk
                #data = JSON.parse chunk
        req.end()
        assert.func cb

    # 获取仓库列表
    getModuleNames : (cb)->
        projects = @getProjects_!
        list = []
        if @usePrefix_
            list.push project.name.replace(@prefix,"") for project in projects
        else
            list.push project.name for project in projects
        cb null, list

    # 根据模块名获取远程仓库地址
    getUrlByModuleName : (module, cb)->
        assert.func cb
        projects = @getProjects_!
        err,has = @hasRepos! module
        if not has
            cb null,null
            return false
        for project in projects
            if project.name is @name(module)
                url = project.ssh_url_to_repo
        cb null, url

    # 根据名称返回对应的url
    getUrlsByModuleNames : (modules, cb)->
        assert.func cb
        list = []
        for module in modules
            err,url = @getUrlByModuleName! module
            if not url
                list.push { module:module, url :url}
            else
                cb  "附加模块 [#{module}] 不存在"
                reurn false
        cb null, list
        return true

    # 获取用户uid
    getUidByUsername:(username,cb)->
        users = @getUsers_!
        for user in users
            if user.username is username
                cb user.id
                return true
        cb null
        return false

    # 获取工程id
    getPidByGitname:(gitname,cb)->
        projects = @getProjects_!
        for project in projects
            if project.name is @name(gitname)
                cb project.id
                return true
        cb null
        return false

    # 添加用户user到名称为gitname的仓库
    addUserToRepos : (username, gitname, cb)->
        assert.func cb
        # access_level
        # GUEST     = 10
        # REPORTER  = 20
        # DEVELOPER = 30
        # MASTER    = 40
        # OWNER     = 50
        # default : DEVELOPER
        uid = @getUidByUsername! username
        pid = @getPidByGitname! gitname
        if pid and uid
            user = @gitlab.projects.members.add! pid, uid, null
            cb null,true
        else
            cb null,false

    # 删除用户user到名称为gitname的仓库
    removeUserFromRepos : (username, gitname, cb)->
        assert.func cb
        uid = @getUidByUsername! username
        pid = @getPidByGitname! gitname
        if pid and uid
            project = @gitlab.projects.members.remove! pid, uid
            cb null,true
        else
            cb null,false

    checkoutReposTo :(name,directory,cb)->
        assert.func cb


module.exports =  GitManager

# test
if require.main is module
    gm = new GitManager

    testGetProjects = () ->
        projects = gm.getProjects_!
        console.log project.name for project in projects
        # projects = gm.getProjects_!
        # console.log project.name for project in projects
    # testGetProjects()

    testHasRepos = () ->
        err,has = gm.hasRepos! "gg"
        console.log has
    # testHasRepos()

    testInitRepos = () ->
        err,url = gm.initRepos! "gg"
        console.log url
    # testInitRepos()

    testRemoveRepos = () ->
        err,success = gm.removeRepos! "deploy"
        console.log success
    testRemoveRepos()

    testGetModuleNames = () ->
        err,list = gm.getModuleNames!
        console.log list
    # testGetModuleNames()

    testGetUrlByModuleName = () ->
        err,url = gm.getUrlByModuleName! "gg"
        console.log url
    # testGetUrlByModuleName()

    testGetUrlsByModuleNames = () ->
        err,list = gm.getUrlsByModuleNames! ["gg",'a']
        console.log list
    # testGetUrlsByModuleNames()

    testAddUserToRepos = () ->
        err,success = gm.addUserToRepos! "lixinwei",'gg'
        console.log success
    # testAddUserToRepos()

    testRemoveUserFromRepos = () ->
        err,success = gm.removeUserFromRepos! "lixinwei",'gg'
        console.log success
    # testRemoveUserFromRepos()
