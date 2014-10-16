fs = require 'fs'
path = require 'path'

fse = require "fs-extra"
program = require "commander"

prettyPrintHtml = require("html").prettyPrint
request = require "request"
cheerio = require "cheerio"
async = require "async"

mfe2static = {}

formatHtml = (source)->
    prettyPrintHtml source, {
        indent_size: 4
        indent_char: ' '
        max_char: 1000,
        brace_style: 'expand'
        unformatted:[
            'bdo' 
            'em' 
            'strong'
            'dfn'
            'code'
            'samp'
            'kbd'
            'var'
            'cite'
            'abbr'
            'acronym'
            'q'
            'sub'
            'sup'
            'tt'
            'i'
            'b'
            'big'
            'small'
            'u'
            's'
            'strike'
            'font'
            'ins'
            'del'
            'pre'
            'address'
            'dt'
        ]
    }

getHtmlContent = (url,next)->
    options = 
        url: url
        encoding:"utf-8"
        headers:
            'User-Agent': 'zhangzhiwei'
            'Disable-Cache': '1'
    err,response,body = request! options
    if not err and response.statusCode is 200
        next null,body
    else
        next "get html error"

removeBlankLine = (t)-> t.replace /^\s*$/g,""

help = ()->
    console.log "+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+"
    console.log "mfe2static <URL> <name>"
    console.log "+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+"

downloadFile = (url,main,dir,next)->
    options = 
        url: url
        headers:
            'User-Agent': 'zhangzhiwei'
            'Disable-Cache': '1'
    p = url
    if url.match /\/\d+x\d+$/
        p = url.replace /\/\d+x\d+$/,""
    if url.match /\/\d+$/
        p = url.replace /\/\d+$/,""        
    filename = path.basename p
    fileSavePath = "./#{main}/#{dir}/#{filename}"

    req = request (options) ,(err)=>
        if err then next err else next null, "./#{dir}/#{filename}"
    req.pipe fs.createWriteStream fileSavePath

mfe2static.run = (argv)->
    if argv.length isnt 4
        help()
        process.exit()

    url = argv[2]
    dir = argv[3]
    fse.mkdirsSync dir
    fse.mkdirsSync "#{dir}/css"
    fse.mkdirsSync "#{dir}/img"
    fse.mkdirsSync "#{dir}/js"

    index_file = "#{dir}/index.html"
    err,responseBody = getHtmlContent! url
    if err
        console.log err
        process.exit()
    htmlCnt = formatHtml responseBody

    $ = cheerio.load htmlCnt,{
        normalizeWhitespace: false
        xmlMode: true
        lowerCaseTags: true
    }

    scripts = $("script")
    err = async.each! scripts, (s,next)=>
        script = $ s
        src = script.attr "src"        
        if src and src.length
            err,jsFilePath = downloadFile! src,dir, "js"
            if err
                next err
            else
                script.attr "src",jsFilePath
                next null
        else
            txt = script.text()
            if (/_bd_share_config/g.test txt) or (/cnzz_protocol/g.test txt) or (/_bdhmProtocol/g.test txt)
                script.remove();
            next null
    if err 
        console.log err
        process.exit()


    links = $("link")
    err = async.each! links, (l,next)=>
        link = $ l
        if (link.attr "rel") isnt "stylesheet"
            next null
        else
            href = link.attr "href" 
            if href and href.length
                err,cssFilePath = downloadFile! href,dir, "css"
                if err
                    next err
                else
                    link.attr "href",cssFilePath
                    next null
            else
                next null
    if err 
        console.log err
        process.exit()

    imgs = $("img")
    err = async.each! imgs, (i,next)=>
        img = $ i
        src = img.attr "src"
        if src and src.length
            err,imgFilePath = downloadFile! src,dir, "img"
            if err
                next err
            else
                img.attr "src",imgFilePath
                next null
        else
            next null
    if err 
        console.log err
        process.exit()

    html = $.html()
    html = formatHtml html
    err = fse.outputFile index_file, html
    if err
        console.log err
        process.exit()
    return 

main = (argv)-> mfe2static.run argv

module.exports.run = main;

# ###### 修改文件 ########
# 
# # 连接mfe命令
# cd ~/mofang/workspace/mfe/mfe-cli && npm link .
# # 部署文件到99
# cd ~/mofang/workspace/ && mfe release -d 99s,99t -Dw
# # 修改模板文件
# subl ~/mofang/workspace
# 
# ......修改文件预览.........

# ###### 读取相关资源文件 ########
#
# # 创建新目录
# mkdir -p ~/mofang/HTML/new_page ~/mofang/HTML/new_page/js ~/mofang/HTML/new_page/css ~/mofang/HTML/new_page/img
# 
# 
# # 发布到本地服务服务器
# cd ~/mofang/workspace/ && mfe release -pD
# 
# # 复制statics/js/v3/mfm
# cp -rf ~/.mfe-tmp/www/statics/js/v3/mfm ~/mofang/HTML/new_page/js
# 
# # 复制静态内容
# cp -rf ~/.mfe-tmp/www/statics/js/v3/loader/dd_belatedpng.js ~/mofang/HTML/new_page/js/dd_belatedpng.js
# cp -rf ~/.mfe-tmp/www/statics/js/v3/loader/html5shiv.js ~/mofang/HTML/new_page/js/html5shiv.js
#
# 
# # 发布代码到测试机器
# cd ~/mofang/workspace/ && mfe release -d 99s,99t -pD
# 
# # 连接mfe2statics命令
# cd ~/mfm && npm link .
# 
# # 抓去页面内容
# cd ~/mofang/HTML/ && mfe2static http://luobo2.mofang.com/ new_page
# cd ~/mofang/HTML/ && mfe2static http://www.mofang.com/bzwx/ new_page

# ####### 整理html,修改连接、删除无用js文件 ######
# 
# ... 模板修改提交到git仓库
# 


# TODO:
# 1. parse css
# 2. parse javascript
# 3. add render support for hao123
# 


