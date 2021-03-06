// Generated by ToffeeScript 1.6.3-1
var AskQuestion, DeployEdit, JsonStore, NameBaseDeploy, fs, util,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

fs = require('fs');

util = require('util');

NameBaseDeploy = require('./DeployBase').NameBaseDeploy;

AskQuestion = require('./DeployAdd').AskQuestion;

JsonStore = require("../JsonStore");

DeployEdit = (function(_super) {
  __extends(DeployEdit, _super);

  function DeployEdit(name, cmd, next) {
    DeployEdit.__super__.constructor.call(this, name, cmd, next);
  }

  DeployEdit.prototype.onFileExists_ = function() {
    var store,
      _this = this;
    store = new JsonStore(this.filename);
    return new AskQuestion(true, store, function(err, answers) {
      store.json.name = _this.name;
      store.save();
      return _this.commitChanges_("edit deploy " + _this.name, _this.next);
    });
  };

  return DeployEdit;

})(NameBaseDeploy);

module.exports = {};

module.exports.DeployEdit = DeployEdit;
