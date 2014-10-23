var _s = require('underscore.string');

function BaseDeploy () {

}
BaseDeploy.prototype.name = null;
{

}

conf.BaseDeploy = BaseDeploy;

fis.config.set('roadmap.domain', "http://127.0.0.1:8080");

// fis.config.set('roadmap.domain', "http://127.0.0.1:8080");
// // 静态文件
// fis.config.set("deploy.local_statics", {
//     from: "/statics",
//     to: "./__output__",
//     exclude: mfe_conf.exclude_statics
// });
// // 模板文件
// fis.config.set("deploy.local_templates", {
//     from: "/templates",
//     to: "./__output__/phpcms",
//     exclude: mfe_conf.exclude_templates
// });
conf.exclude_statics = /\/test\//;
conf.exclude_templates = /\/test\//;

conf.parseObject = function(json) {
	if(!json.name){
    	return false;
    }
    fis.config.set('roadmap.domain',json.domain || "http://localhost:8080");
    // 静态文件

	var d = {};
	d[json.name + "_statics"] = {
        receiver:json.receiver_statics || null,
		from: "/statics",
		to: json.output_statics || "../__output__",
		exclude: conf.exclude_statics
	};
	d[json.name + "_templates"] = {
        receiver:json.receiver_templates || null,
		from: "/templates",
		to: json.output_templates || "../__output__",
		exclude: conf.exclude_templates
	};
	var deploy = {
		deploy:d
	};
    fis.config.merge(deploy);
	return true;
};

conf.parseDeploy = function(config) {

	if (!config.filename){
		return true;
	}
	var json = require(config.filename);
	if(!json.name){
    	return false;
    }
    // if (json.receiver_statics === _s.trim("http://qiniu") && json.output_statics === _s.trim("qiniu")) {
    //     fis.qiniu = true;
    // }
	conf.parseObject(json);
	return true;
};

var o = {
    name:"local",
    domain:"http://localhost:8080",
    statics:"../__output__",
    templates:"../__output__"
};
conf.parseObject(o);

