fs = require 'fs'
program = require 'commander'

# 标识命令
DeployAdd = require('./cmd/DeployAdd').DeployAdd
DeployList = require('./cmd/DeployList').DeployList
DeployRemove = require('./cmd/DeployRemove').DeployRemove
DeployEdit = require('./cmd/DeployEdit').DeployEdit

# 模块命令
ModuleStart = require('./cmd/ModuleStart').ModuleStart
ModuleComplete = require('./cmd/ModuleComplete').ModuleComplete
ModuleRemove = require('./cmd/ModuleRemove').ModuleRemove
ModuleList = require('./cmd/ModuleList').ModuleList
ModuleDeploy = require('./cmd/ModuleDeploy').ModuleDeploy

# TODO:工程命令
Project = require('./cmd/Project').Project

# 工具命令
Upgrade = require('./cmd/Upgrade').Upgrade


init_user = require './init_user'

range = (val)-> val.split('..').map(Number)

list = (val)-> val.split ','

mfe.cli = {}

mfe.cli.run = (argv)->
    if not fs.existsSync mfe.path.data then fs.mkdirSync mfe.path.data
    if not mfe.user_conf.json.init
        init_user()
        return false
    program
        .version('0.0.1')

    # 添加业务模块 ++
    program
        .command('sm <module>')
        .description('[start module] 创建/切换到业务模块module')
        .option('-a, --add <name>[,<name2>,[...]]', '追加的模块', list)
        .option('-d, --deploy <name>', '按照name标识部署')
        .option('-o, --optimize <short>', 'fis优化参数mopDu')
        .option('-c, --channel [number]', '模板服务器频道号')
        .option('-M, --mfe', '强制推送mfe的php支撑文件')
        .action (module, cmd)->
            msg = "准备切换到业务模块[#{module}]"
            msg_end = "已切换到业务模块[#{module}]"
            if cmd.deploy
                msg += ",使用[#{cmd.deploy}]标识部署产出文件"
                msg_end += ",部署标识[#{cmd.deploy}]产出文件成功!"
            console.log msg
            new ModuleStart module, cmd, (err)->
                if err then console.log(err)
                else console.log(msg_end)
                process.exit()

    # 完成业务模块
    program
        .command('cm <module>')
        .description('[complete module] 完成业务模块module的开发')
        .action (module, cmd)->
            new ModuleComplete module, cmd, (err)->
                if err
                    console.log err
                else
                    console.log "完成业务模块", module, "的开发修改已提交"
                process.exit()

    # 删除业务模块  +++
    # TODO:
    #    o. fixed compile nginx support PUT\DELETE http method
    program
        .command('rm <module>')
        .description('[remove module] 删除业务模块')
        .action (module, cmd)->
            new ModuleRemove module, cmd, (err)->
                if err
                    console.log err
                else
                    console.log "删除业务模块[#{module}], 删除所有部署标识上的模块#{module}"
                process.exit()

    # 列出业务模块
    program
        .command('lm')
        .description('[list module] 列出全部业务模块')
        .action (module, cmd)->
            new ModuleList null,cmd,(err)->
                if err
                    console.log err
                process.exit()

    # 按照标识布署模块
    program
        .command('dm <module>')
        .description('[deploy module] 布署模块')
        .option('-d --deploy <name>', '布署标识', list)
    	.option('-c --channel [channelid]', '通道id')
    	.option('-f --cleanup', '布署前清空通道')
    	.option('-p --pre_release', '预备上线,返回模板包id')
    	.option('-Q --qiniu', '是否发布静态文件到七牛')
    	.option('-r --release', '直接布署模板到线上')
        .action (name, cmd)->
            new ModuleDeploy name,cmd,(err)->
                if err
                    console.log err
                else
                    console.log "布署模块[#{name}]完成..."
                process.exit()

    # 添加布署标识
    program
        .command('ad <name>')
        .description('[add deploy] 添加明为name的布署标识')
        .action (name, cmd)->
            new DeployAdd name,cmd,(err)->
                if err
                    console.log err
                else
                    console.log "创建标识符[#{name}]成功"
                process.exit()

    # 删除布署标识
    program
        .command('rd <name>')
        .description('[remove deploy] 删除布署标识')
        .action (name, cmd)->
            new DeployRemove name,cmd,(err)->
                if err then console.log(err)
                process.exit()
    # 编辑布署文件
    program
        .command('ed <name>')
        .description('[edit deploy] 编辑布署标识')
        .action (name, cmd)->
            new DeployEdit name,cmd,(err)->
                if err then console.log(err)
                process.exit()

    # 列出布署文件
    program
        .command('ld')
        .option('-u, --user <name>', '用户名')
        .description('[list deploy] 列出全部布署标识')
        .action (cmd)->
            new DeployList cmd,(err)->
                if err then console.log(err)
                process.exit()

    # 布署整个工程 ++++++++++
    # TODO:
    #   III. a module may be belongs to a project
    #   o. add or remove a project identifier
    #   o. module name can be add to or remove from a project identifier
    #   o. deploy the whole project via a identifier
    #   o. the identifier shared via deploy repos
    program
        .command('dp <project>')
        .option('-d, --deploy <name>', '布署标识')
        .description('[deploy project] 布署整个工程')
        .action (name, cmd)->
            new Project name,cmd,(err)->
                if err
                    console.log(err)
                else
                    console.log("[#{name}]发布成功")
                process.exit()

    # 更新mfe工具
    program
        .command('up')
        .description('[upgrade] 更新mfm工具')
        .action (name, cmd)->
            console.log "正在升级mfm布署工具..."
            new Upgrade name,cmd,(err, version)->
                if err
                    console.log err
                    console.log "mfm升级失败!"
                else
                    console.log "mfm升级成功..."
                    console.log "当前版本为:" + version
                process.exit()

    # 帮助信息
    help = ()-> process.stdout.write program.helpInformation().replace '*', ""

    # 无效命令
    program
        .command('*')
        .action (env)->
            console.log "******************************"
            console.log "**** ERROR:#{env}为无效命令"
            console.log "******************************"
            help()
            process.exit()

    # 转换参数
    program.parse(process.argv)

    # 默认打印帮助信息
    if not program.args.length
        help()
        process.exit()
