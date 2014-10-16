(function() {
  var ModulePrepareDirectory, ModuleStart, assert, fs, util, utils, work_dir_shell, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ModulePrepareDirectory = require('./ModulePrepareDirectory').ModulePrepareDirectory;

  util = require('util');

  assert = require('assert-plus');

  fs = require('fs');

  utils = require('../utils');

  work_dir_shell = utils.work_dir_shell;

  ModuleStart = (function(_super) {
    __extends(ModuleStart, _super);

    function ModuleStart() {
      _ref = ModuleStart.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ModuleStart.prototype.templatesServerConfig_ = function(cb) {
      var channelId, deployContent, deployFilename, uname, work_dir;
      if (this.cmd.channel) {
        this.cmd.deploy = "templates_server";
        if (this.cmd.optimize && this.cmd.optimize.indexOf("D" !== -1)) {
          this.cmd.optimize = "D" + this.cmd.optimize;
        } else {
          this.cmd.optimize = "D";
        }
        work_dir = mfe.path.work_dir;
        uname = mfe.user_conf.json.username;
        channelId = this.cmd.channel === true ? uname : "" + uname + "_" + this.cmd.channel;
        deployContent = "{\n    \"domain\": \"http://templates.mofang.com/channel/" + channelId + "\",\n    \"receiver_statics\": \"http://templates.mofang.com/receiver.php\",\n    \"output_statics\": \"channel/" + channelId + "\",\n    \"receiver_templates\": \"http://templates.mofang.com/receiver.php\",\n    \"output_templates\": \"channel/" + channelId + "\",\n    \"name\": \"templates_server\"\n}";
        deployFilename = "" + work_dir + "/deploy/" + uname + "/templates_server.json";
        fs.writeFileSync(deployFilename, deployContent);
      }
      return cb();
    };

    ModuleStart.prototype.prepareComplete = function(cb) {
      var cmd, cmds, content, err, filename, main_cmd, moduleName,
        _this = this;
      assert.func(cb);
      work_dir_shell(["mfe server clean"], function() {
        var _i, _len, _ref1;
        err = arguments[0];
        if (err) {
          return cb(err);
        }
        cmds = [];
        if (!_this.cmd.deploy && !_this.cmd.mfe) {
          cmd = "mfe release -r mfe";
          if (_this.cmd.optimize) {
            cmd += " -" + _this.cmd.optimize;
          }
          cmds.push(cmd);
        }
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
            }
            cmds.push(cmd);
          }
        }
        main_cmd = "mfe release -w -r " + _this.module;
        if (_this.cmd.deploy) {
          main_cmd += " -d " + _this.cmd.deploy + "_statics," + _this.cmd.deploy + "_templates";
        }
        if (_this.cmd.optimize) {
          main_cmd += " -" + _this.cmd.optimize;
        }
        cmds.push(main_cmd);
        content = "" + (cmds.join("\n")) + "\n";
        filename = "" + mfe.path.work_dir + "/watch.sh";
        fs.writeFileSync(filename, content);
        fs.chmodSync(filename, "777");
        console.log("");
        console.log("++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++");
        console.log(" 当前业务模块【" + _this.module + "】                   ");
        console.log("++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++");
        console.log("+   按Ctrl + C 退出                     +");
        console.log("+   退出后,可以手动运行以下命令:        +");
        console.log("+       ./watch.sh                      +");
        console.log("++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++");
        return work_dir_shell(cmds, cb);
      });
    };

    return ModuleStart;

  })(ModulePrepareDirectory);

  module.exports = {};

  module.exports.ModuleStart = ModuleStart;

}).call(this);
