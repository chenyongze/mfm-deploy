(function() {
  var ModuleDeploy, ModulePrepareDirectory, assert, fs, util, utils, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ModulePrepareDirectory = require('./ModulePrepareDirectory').ModulePrepareDirectory;

  util = require('util');

  assert = require('assert-plus');

  fs = require('fs');

  utils = require('../utils');

  ModuleDeploy = (function(_super) {
    __extends(ModuleDeploy, _super);

    function ModuleDeploy() {
      _ref = ModuleDeploy.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ModuleDeploy.prototype.templatesServerConfig_ = function(cb) {
      var channelId, deployContent, deployFilename, uname, work_dir;
      if (!this.cmd.deploy) {
        this.cmd.deploy = "templates_server";
        if (this.cmd.optimize && this.cmd.optimize.indexOf("D" !== -1)) {
          this.cmd.optimize = "D" + this.cmd.optimize;
        } else {
          this.cmd.optimize = "D";
        }
        work_dir = mfe.path.work_dir;
        uname = mfe.user_conf.json.username;
        channelId = this.cmd.channel === true ? uname : "" + uname + "_" + this.cmd.channel;
        deployContent = "{\n    \"domain\": \"http://sts0.mofang.com\",\n    \"receiver_statics\": \"http://qiniu\",\n    \"output_statics\": \"qiniu\",\n    \"receiver_templates\": \"http://templates.mofang.com/receiver.php\",\n    \"output_templates\": \"release\",\n    \"name\": \"templates_server\"\n}";
        deployFilename = "" + work_dir + "/deploy/" + uname + "/templates_server.json";
        fs.writeFileSync(deployFilename, deployContent);
      }
      return cb();
    };

    ModuleDeploy.prototype.prepareComplete = function(cb) {
      var answer, cmd, cmds, content, err, filename, main_cmd, moduleName, out,
        _this = this;
      assert.func(cb);
      if (!this.cmd.deploy) {
        return cb("部署标识未指定 -d <name>");
      }
      utils.ask_if_v(("警告:将要以【" + this.cmd.deploy + "】规则,部署模块【" + this.module + "】及相关资源到线上,模块和部署标识是否正确").red, function() {
        var _i, _len, _ref1;
        err = arguments[0], answer = arguments[1];
        if (!answer) {
          return _this.next("模块【" + _this.module + "】的部署操作取消");
        }
        cmds = [];
        _ref1 = mfe.defaultModules;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          moduleName = _ref1[_i];
          if (_this.module !== moduleName && moduleName !== "mfe") {
            cmd = "mfe release -r " + moduleName;
            if (_this.cmd.deploy) {
              cmd += " -d " + _this.cmd.deploy + "_statics," + _this.cmd.deploy + "_templates";
            }
            if (_this.cmd.optimize) {
              cmd += " -" + _this.cmd.optimize;
              cmd += " --verbose";
            }
            cmd += " -moDup";
            cmds.push(cmd);
          }
        }
        main_cmd = "mfe release -r " + _this.module;
        if (_this.cmd.deploy) {
          main_cmd += " -d " + _this.cmd.deploy + "_statics," + _this.cmd.deploy + "_templates";
        }
        if (_this.cmd.optimize) {
          main_cmd += " -" + _this.cmd.optimize;
          main_cmd += " --verbose";
        }
        main_cmd += " -moDup";
        cmds.push(main_cmd);
        content = "" + (cmds.join("\n")) + "\n";
        filename = "" + mfe.path.work_dir + "/release.sh";
        fs.writeFileSync(filename, content);
        fs.chmodSync(filename, "777");
        utils.work_dir_shell2(cmds, function() {
          err = arguments[0], out = arguments[1];
          fs.writeFileSync('v.log', out);
          return cb(null);
        });
      });
    };

    return ModuleDeploy;

  })(ModulePrepareDirectory);

  module.exports = {};

  module.exports.ModuleDeploy = ModuleDeploy;

}).call(this);
