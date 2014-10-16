fs = require 'fs'
fse = require 'fs-extra'
program = require 'commander'
dos2unix = require "./mfutil/dos2unix"

mfutil = {}

g = ()->
    base = 16 # base font size 16px
    min = 320
    max = 1080
    step = 1

    g = (w)-> base /  720 * w
    t = (h,f) ->
        """
@media only screen
#{h} {
    html{
        font-size:#{f}px !important;
    }
}

"""
    str = ""
    i = min
    while i <= max
        str += t "and (width: #{i}px)",g i
        i += step
    fs.writeFileSync "statics/css/g.css",str

# generate global media file
generate = ()->
    base = 16 # base font size 16px
    min = 320
    max = 1080
    step = 10

    g = (w)-> base /  720 * w
    t = (h,f) ->
        """
@media only screen
#{h} {
    html{
        font-size:#{f}px !important;
    }
}

"""
    str = ""
    i = min
    while i <= max
        if i is min then str += t "and (max-width: #{i}px)",g i
        str += t "and (min-width: #{i}px) and (max-width: #{ i + step}px)",g i
        if i is max then str += t "and (min-width: #{i}px)",g i
        i += step
    fs.writeFileSync "statics/css/g.css",str


# convert ..px to mfe-px2rem of an css/scss file
torem = (filename)->
    cnt = fs.readFileSync filename,{encoding:'utf-8'}
    if not (/@function\s+mfe\-px2rem/ig.test cnt)
        cnt = cnt.replace /(-*\d+)\s*px/ig,"mfe-px2rem($1)"
    # append rem mixin
    remfn = """
@function mfe-px2rem($px) {
    @return $px/16 + rem;
}

"""
    cnt = remfn + cnt
    fs.writeFileSync filename,cnt,{encoding:'utf-8'}



# generate compass config file for 
generate_config = ()->
    cnt = """
# Require any additional compass plugins here.

# Set this to the root of your project when deployed:
http_path = "/"
css_dir = "statics/css"
sass_dir = "statics/sass"
images_dir = "statics/img"
javascripts_dir = "statics/js"

# You can select your preferred output style here (can be overridden via the command line):
# output_style = :expanded or :nested or :compact or :compressed

# To enable relative paths to assets via compass helper functions. Uncomment:
# relative_assets = true

# To disable debugging comments that display the original location of your selectors. Uncomment:
# line_comments = false


# If you prefer the indented syntax, you might want to regenerate this
# project again passing --syntax sass, or you can uncomment this:
# preferred_syntax = :sass
# and then run:
# sass-convert -R --from scss --to sass sass scss && rm -rf sass && mv scss sass

"""
    fs.writeFileSync "config.rb",cnt,{encoding:"utf-8"}

# setup the compass env
compass = ()->
    # make scss directory
    fse.mkdirsSync "statics/scss"

    # add compass config files
    generate_config()

# setup the mobile env
mobile = ()->
    # create compass env
    compass()

    # generate media css
    generate()

    # tip for change
    console.log "【mfutil torem <filename>】 to convert px to rem"

# check if the dir include git and is a mft module directory
check_dir = ()->
    # TODO:添加文件夹检测
    # 
    # console.log process.cwd()
    return true

list = (val)-> val.split ','

mfutil.run = (argv)->

    # check if the current directory is a mft module
    if not check_dir()  then return false

    program
        .version('0.0.1')

     # 生成sass环境
    program
        .command('env <name>')
        .description('generate compass/mobile env')
        .action (name,cmd)->
            if name is compass
                compass()
            if name is mobile
                mobile()
            process.exit()

    # 生成响应式文件
    program
        .command('g [filename]')
        .description('generate global responsive file')
        .action (cmd)->
            g()
            process.exit()

     # 生成响应式文件
    program
        .command('generate [filename]')
        .description('generate global responsive file')
        .action (cmd)->
            generate()
            process.exit()

    # 编辑部署文件
    program
        .command('torem <filename>')
        .description('convert px to rem')
        .action (filename, cmd)->
            torem filename
            process.exit()

     # 转换dos格式到unix格式换行符
    program
        .command('dos2unix <directory>')
        .option('-e, --ext <ext1>[,ext2>,[...]]', '追加的模块', list)
        .description('convert files from dos to unix line endings')
        .action (directory ,cmd)->
            err = dos2unix! directory, filter:cmd.ext
            if err
                console.log err
            else
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

main = (argv)-> mfutil.run argv

module.exports.run = main;



