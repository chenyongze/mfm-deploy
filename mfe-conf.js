var util = require("util");
var events = require("events");
var path = require("path");

var conf = {};

// 导出到全局变量
Object.defineProperty(global, 'conf', {
    enumerable : true,
    writable : false,
    value : conf
});

conf.init = function(dirname) {
    if (!dirname) {
        throw new Error("dirname must be set.");
    }
    var dir = dirname.split(path.sep);
    var module_name = dir.pop();

    conf.module_name = module_name;
    conf.templates = "templates/";
    conf.statics = "statics/";

    conf.version = 4;
    conf.use_version = true;

    var statics_dir = null;
    var tpl_dir = null;
    var map_dir = null;

    if (conf.use_version) {
        var v = "v" + conf.version + "/";
        statics_dir = conf.statics + v + module_name + "/";
        tpl_dir = conf.templates + v + module_name + "/";
        map_dir = conf.templates + v + "fis_config/";
    }else{
        statics_dir = conf.statics + module_name + "/";
        tpl_dir = conf.templates + module_name + "/";
        map_dir = conf.templates + "fis_config/";
    }
    conf.tpl_dir = tpl_dir;
    conf.statics_dir = statics_dir;
    conf.map_dir = map_dir;
};

function BaseConfig () {
    this.base_();
    this.init();
    this.csssprites_();
    this.lint_();
    this.smarty_();
}
util.inherits(BaseConfig, events.EventEmitter);

BaseConfig.prototype.init = function() {
  this.dirs_();
  this.files_();
};
BaseConfig.prototype.dirs_ = function(){

};
BaseConfig.prototype.files_ = function(){

};
BaseConfig.prototype.base_ = function() {

    fis.config.merge({
        ////////////////////
        // Fis 插件配置
        ////////////////////
        modules : {
            //编译器插件配置节点
            parser : {
                //.coffee后缀的文件使用fis-parser-coffee-script插件编译
                coffee : 'coffee-script',
                //.less后缀的文件使用fis-parser-less插件编译
                less : 'less'
            },
            lint : {
                js : 'jshint'
            }
        },
        project:{
            charset:"utf8",
            md5Length : 7,
            md5Connector:"_",
            exclude:null
        },

        settings : {
            parser : {
                'coffee-script' : {
                    //不用coffee-script包装作用域
                    bare : true
                }
            },
            postprocessor : {
                //fis-postprocessor-jswrapper插件配置数据
                jswrapper : {
                    //使用define包装js组件
                    type : 'amd'
                }
            },
            lint : {
                jshint : {
                    //排除对lib和jquery、backbone、underscore的检查
                    // ignored : [ 'lib/**', /jquery|backbone|underscore/i ],
                    //使用中文报错
                    i18n : 'zh-CN'
                }
            },
            optimizer : {
                'uglify-js' : {
                    mangle : {
                        //不要压缩require关键字，否则seajs会识别不了require
                        except : [ 'require' ]
                    }
                },
                'html-compress':{}
            }
        },

        ////////////////////////
        // 打包设置
        ///////////////////////

        pack : {

        },

        ///////////////////////
        // 发布环境
        ///////////////////////
        //
        // 使用: mfe release --dest <deploy.config>
        //
        deploy : {

        }
    });

    ////////////////////
    // 目录发布规则
    ////////////////////
    var roadmap = fis.config.get('roadmap') || {};
    roadmap.domain = roadmap.domain || 'http://localhost:8080';
    roadmap.ext = {
        // less输出为css文件
        less : 'css',
        // coffee输出为js文件
        coffee : 'js'
    };
    roadmap.path = [];
    // updata roadmap settings
    fis.config.merge({
        roadmap : roadmap
    });

    fis.config.set('livereload.port', 35729);
};
BaseConfig.prototype.csssprites_ = function() {
    // 如果要兼容低版本ie显示透明png图片，请使用pngquant作为图片压缩器，
    // 否则png图片透明部分在ie下会显示灰色背景
    // 使用spmx release命令时，添加--optimize或-o参数即可生效
    // fis.config.set('settings.optimzier.png-compressor.type', 'pngquant');

    // csssprite处理时图片之间的边距，默认是3px
    // fis.config.set('settings.spriter.csssprites.margin', 20);
};
BaseConfig.prototype.lint_ = function() {

    // 设置jshint插件要排除检查的文件，默认不检查lib、jquery、backbone、underscore等文件
    // 使用spmx release命令时，添加--lint或-l参数即可生效
    // fis.config.set('settings.lint.jshint.ignored', [ 'lib/**', /jquery|backbone|underscore/i ]);
};
BaseConfig.prototype.smarty_ = function() {
    ////////////////////////////////
    //+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
    // 模板引擎配置
    //+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
    ////////////////////////////////

    fis.config.set('settings.smarty.left_delimiter','{');
    fis.config.set('settings.smarty.right_delimiter','}');
};
conf.BaseConfig = BaseConfig;




function ModuleConfig () {
    BaseConfig.call(this);
}
util.inherits(ModuleConfig, BaseConfig);
ModuleConfig.prototype.dirs_ = function() {
    fis.config.set("project.include",/(^\/page\/|^\/statics\/|^\/widget\/|^\/test\/)/i);
};
ModuleConfig.prototype.files_ = function() {
    var roadmap = fis.config.get('roadmap') || {};
    ////////////////////
    // 目录发布规则
    ////////////////////
    roadmap.path = [
        /////////////////////////////////////////////
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        // 测试目录
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        /////////////////////////////////////////////
        {
            // 测试 目录下的模板文件
            reg : /^\/test\/(.*\.tpl)$/,
            //发布到/statics/目录下
            release : conf.tpl_dir + 'test/$1'
        },
        {
            // 测试 目录下的其他全部发布
            reg : /^\/test\/(.*\.*)$/,
            //发布到/statics/目录下
            release : conf.statics_dir + 'test/$1'
        },
        /////////////////////////////////////////////
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        // 静态目录
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        /////////////////////////////////////////////
        {
            // statics 目录下的文件全部发布
            reg : /^\/statics\/(.*\.*)$/,
            //发布到/statics/目录下
            release : conf.statics_dir + '$1'
        },
        /////////////////////////////////////////////
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        // 模板目录
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        /////////////////////////////////////////////
        // page发布到templates/{name}/* 目录
        {
            reg: /^\/page\/(.*\.tpl)$/i,
            isMod : true,
            url : conf.tpl_dir + '$1',
            id:'$1',
            isHtmlLike : true,
            release : conf.tpl_dir + '$1'
        },
        /////////////////////////////////////////////
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        // widget 目录 tpl
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        /////////////////////////////////////////////
        // page发布到templates/{name}/* 目录
        {
            reg: /^\/(widget\/.*\.tpl)$/i,
            isMod : true,
            url : conf.tpl_dir + '$1',
            id:'$1',
            isHtmlLike : true,
            release : conf.tpl_dir + '$1'
        },
        /////////////////////////////////////////////
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        // widget 目录静态文件
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        /////////////////////////////////////////////
        {
            // statics 目录下的文件全部发布
            reg : /^\/(widget\/.*\.*)$/,
            //发布到/statics/目录下
            release : conf.statics_dir + '$1'
        },
        ///////////////////////////////////////////////////
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        //  其他文件
        // +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
        ///////////////////////////////////////////////////
        {
            //map.json文件
            reg : 'map.json',
            //发布到/tmplates/{test}/map.json
            release : conf.map_dir + conf.module_name + '-map.json'
        },
        {
            //sh文件
            reg : '**.sh',
            //不要发布
            release : false
        },
        {
            //readme文件，不要发布
            reg : /^\/readme.md$/i,
            release : false
        },
        {
            // 其他文件不发布
            reg : /^\/(.*)$/,
            release : false
        }
    ];

    // updata roadmap settings
    fis.config.merge({
        roadmap : roadmap
    });
};
conf.ModuleConfig = ModuleConfig;



function MfeModuleConfig () {
    BaseConfig.call(this);
}
util.inherits(MfeModuleConfig, BaseConfig);
MfeModuleConfig.prototype.dirs_ = function() {
    fis.config.set("include",/(^\/page\/|^\/statics\/|^\/widget\/|^\/test\/)/i);
};
MfeModuleConfig.prototype.files_ = function() {
    fis.config.merge({
        ////////////////////
        // 目录发布规则
        ////////////////////
        roadmap : {
            path : [
            ]
        }
    });
};
conf.MfeModuleConfig = MfeModuleConfig;
