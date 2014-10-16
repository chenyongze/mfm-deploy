mfe = module.exports = {}

# 导出到全局变量
Object.defineProperty global, 'mfe', {
    enumerable: true
    writable: false
    value: mfe
}

# debug
last = Date.now()
mfe.time = (title)->
    console.log(title + ' : ' + (Date.now() - last) + 'ms')
    last = Date.now()

mfe.log = ()-> console.log.apply(@, arguments)

mfe.error = ()-> console.error.apply(@, arguments)

# 全局路径处理
mfe.path = {}

# mfe安装路径
mfe.path.cli = __dirname + "/.."

# data 用户数据,此目录不不被提交
mfe.path.data = mfe.path.cli + "/data"

# templates 初始化工程时需要的目录结构，部署文件 ignore 等模板文件
mfe.path.templates = mfe.path.cli + "/templates"

# 当前工作目录
mfe.path.work_dir = process.cwd()

# 默认模块
mfe.defaultModules = [
    'common'
    'modules'
    'mfe'
]

JsonStore = require("./JsonStore")
GitManager = require("./GitManager")

# 读取用户设置
mfe.user_conf = new JsonStore(mfe.path.data + "/user.json")
require("./cli")
