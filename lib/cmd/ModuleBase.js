// Generated by ToffeeScript 1.6.3-4
(function() {
  var CmdBase, ModuleBase, NameModuleBase, fs, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  fs = require('fs');

  util = require('util');

  CmdBase = require('./CmdBase').CmdBase;

  ModuleBase = (function(_super) {
    __extends(ModuleBase, _super);

    function ModuleBase(module, cmd, next) {
      ModuleBase.__super__.constructor.call(this, null, cmd, next);
      this.module = module;
    }

    return ModuleBase;

  })(CmdBase);

  NameModuleBase = (function(_super) {
    __extends(NameModuleBase, _super);

    function NameModuleBase(module, cmd, next) {
      var exists;
      NameModuleBase.__super__.constructor.call(this, module, cmd, next);
      exists = fs.existsSync(this.deployDir);
      if (!exists) {
        next("非工作目录，请先初始化工作目录 mfm sm <module>");
      } else {
        this.onDirExists_();
      }
    }

    NameModuleBase.prototype.onDirExists_ = function() {};

    NameModuleBase.prototype.commitChanges_ = function(msg, cb) {
      console.log(msg);
      return cb(null);
    };

    return NameModuleBase;

  })(ModuleBase);

  module.exports = {};

  module.exports.ModuleBase = ModuleBase;

  module.exports.NameModuleBase = NameModuleBase;

}).call(this);
