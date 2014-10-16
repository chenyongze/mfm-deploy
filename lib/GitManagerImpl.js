(function() {
  var Cache, GitManager, Gitlab, assert, credentials, fs, gm, testAddUserToRepos, testGetModuleNames, testGetProjects, testGetUrlByModuleName, testGetUrlsByModuleNames, testHasRepos, testInitRepos, testRemoveRepos, testRemoveUserFromRepos, utils;

  fs = require("fs");

  assert = require('assert-plus');

  utils = require('./utils');

  Gitlab = require("gitlab").ApiV3;

  Cache = require('./Cache');

  credentials = {
    host: "http://git.mofang.com",
    hostname: "git.mofang.com",
    token: "nsC6ioUEVfAdTKBzpStH",
    password: "mofang888",
    login: "mfe@mofang.com",
    user: "mfe"
  };

  function sleep(time, fn) {
    return setTimeout(fn, time);
  };

  GitManager = (function() {
    function GitManager(args) {
      instance;
      var instance;
      this.gitlab = new Gitlab({
        token: credentials.token,
        url: credentials.host,
        password: credentials.password,
        login: credentials.login
      });
      this.email = credentials.login;
      this.cache = new Cache;
      this.usePrefix_ = false;
      GitManager = function() {
        return instance;
      };
      GitManager.prototype = this;
      instance = new GitManager();
      instance.constructor = GitManager;
      return instance;
    }

    GitManager.prototype.prefix = "mfm-";

    GitManager.prototype.name = function(name) {
      if (this.usePrefix_) {
        return this.prefix + name;
      } else {
        return name;
      }
    };

    GitManager.prototype.getProjects_ = function(cb) {
      var all, project, projects,
        _this = this;
      assert.func(cb);
      if (this.cache.get("projects")) {
        cb(this.cache.get('projects'));
        return true;
      }
      this.gitlab.projects.all(function() {
        var _i, _len;
        all = arguments[0];
        projects = [];
        for (_i = 0, _len = all.length; _i < _len; _i++) {
          project = all[_i];
          if (project.owner.email === _this.email) {
            if (_this.usePrefix_) {
              if (project.name.match(/^mfm-/i)) {
                projects.push(project);
              }
            } else {
              projects.push(project);
            }
          }
        }
        _this.cache.set('projects', projects, 4);
        return cb(_this.cache.get('projects'));
      });
    };

    GitManager.prototype.getUsers_ = function(cb) {
      var all, user, users,
        _this = this;
      assert.func(cb);
      if (this.cache.get("users")) {
        cb(this.cache.get('users'));
        return true;
      }
      this.gitlab.users.all({
        per_page: 1000
      }, function() {
        var _i, _len;
        all = arguments[0];
        users = [];
        for (_i = 0, _len = all.length; _i < _len; _i++) {
          user = all[_i];
          users.push(user);
        }
        _this.cache.set('users', users, 20);
        return cb(_this.cache.get('users'));
      });
    };

    GitManager.prototype.hasRepos = function(module, cb) {
      var has, project, projects,
        _this = this;
      assert.string(module);
      assert.func(cb);
      if (!module.length) {
        cb('module name must set');
        return false;
      }
      this.getProjects_(function() {
        var _i, _len;
        projects = arguments[0];
        has = false;
        for (_i = 0, _len = projects.length; _i < _len; _i++) {
          project = projects[_i];
          if (project.name === _this.name(module)) {
            has = true;
          }
        }
        return cb(null, has);
      });
    };

    GitManager.prototype.initRepos = function(module, cb) {
      var err, has, name, project, projects, url,
        _this = this;
      assert.func(cb);
      this.hasRepos(module, function() {
        err = arguments[0], has = arguments[1];
        if (has) {
          _this.getProjects_(function() {
            var _i, _len;
            projects = arguments[0];
            url = null;
            if (!projects) {
              cb(null, "");
              return false;
            }
            for (_i = 0, _len = projects.length; _i < _len; _i++) {
              project = projects[_i];
              if (project.name === _this.name(module)) {
                url = project.ssh_url_to_repo;
              }
            }
            return cb(null, url);
          });
        } else {
          name = _this.name(module);
          _this.gitlab.projects.create({
            name: name
          }, function() {
            project = arguments[0];
            if (project && project.ssh_url_to_repo) {
              _this.cache.clear('projects');
              sleep(1000, function() {
                return cb(null, project.ssh_url_to_repo);
              });
            }
          });
        }
      });
    };

    GitManager.prototype.removeRepos = function(module, cb) {
      var http, id, options, req;
      http = require('http');
      id = encodeURIComponent("" + credentials.user + "/" + module);
      options = {
        hostname: '192.168.1.110',
        port: 80,
        path: "/api/v3/projects/" + id + "?private_token=" + credentials.token,
        method: 'DELETE'
      };
      console.log(options.path);
      req = http.request(options, function(res) {
        res.setEncoding('utf8');
        console.log("statusCode: ", res.statusCode);
        console.log("headers: ", res.headers);
        return res.on('data', function(chunk) {
          return console.log(chunk);
        });
      });
      req.end();
      return assert.func(cb);
    };

    GitManager.prototype.getModuleNames = function(cb) {
      var list, project, projects,
        _this = this;
      this.getProjects_(function() {
        var _i, _j, _len, _len1;
        projects = arguments[0];
        list = [];
        if (_this.usePrefix_) {
          for (_i = 0, _len = projects.length; _i < _len; _i++) {
            project = projects[_i];
            list.push(project.name.replace(_this.prefix, ""));
          }
        } else {
          for (_j = 0, _len1 = projects.length; _j < _len1; _j++) {
            project = projects[_j];
            list.push(project.name);
          }
        }
        return cb(null, list);
      });
    };

    GitManager.prototype.getUrlByModuleName = function(module, cb) {
      var err, has, project, projects, url,
        _this = this;
      assert.func(cb);
      this.getProjects_(function() {
        projects = arguments[0];
        _this.hasRepos(module, function() {
          var _i, _len;
          err = arguments[0], has = arguments[1];
          if (!has) {
            cb(null, null);
            return false;
          }
          for (_i = 0, _len = projects.length; _i < _len; _i++) {
            project = projects[_i];
            if (project.name === _this.name(module)) {
              url = project.ssh_url_to_repo;
            }
          }
          return cb(null, url);
        });
      });
    };

    GitManager.prototype.getUrlsByModuleNames = function(modules, cb) {
      var err, list, module, url, _i, _len,
        _this = this;
      assert.func(cb);
      list = [];
      _i = 0, _len = modules.length;
      function _step() {
        _i++;
        _body();
      };
      function _body() {
        if (_i < _len) {
          module = modules[_i];
          _this.getUrlByModuleName(module, function() {
            err = arguments[0], url = arguments[1];
            if (!url) {
              _step(list.push({
                module: module,
                url: url
              }));
            } else {
              cb("附加模块 [" + module + "] 不存在");
              _step(reurn(false));
            }
          });
        } else {
          _$cb$_0();
        }
      };
      _body();
      function _$cb$_0() {
        cb(null, list);
        return true;
      };
    };

    GitManager.prototype.getUidByUsername = function(username, cb) {
      var user, users,
        _this = this;
      this.getUsers_(function() {
        var _i, _len;
        users = arguments[0];
        for (_i = 0, _len = users.length; _i < _len; _i++) {
          user = users[_i];
          if (user.username === username) {
            cb(user.id);
            return true;
          }
        }
        cb(null);
        return false;
      });
    };

    GitManager.prototype.getPidByGitname = function(gitname, cb) {
      var project, projects,
        _this = this;
      this.getProjects_(function() {
        var _i, _len;
        projects = arguments[0];
        for (_i = 0, _len = projects.length; _i < _len; _i++) {
          project = projects[_i];
          if (project.name === _this.name(gitname)) {
            cb(project.id);
            return true;
          }
        }
        cb(null);
        return false;
      });
    };

    GitManager.prototype.addUserToRepos = function(username, gitname, cb) {
      var pid, uid, user,
        _this = this;
      assert.func(cb);
      this.getUidByUsername(username, function() {
        uid = arguments[0];
        _this.getPidByGitname(gitname, function() {
          pid = arguments[0];
          if (pid && uid) {
            _this.gitlab.projects.members.add(pid, uid, null, function() {
              user = arguments[0];
              return cb(null, true);
            });
          } else {
            return cb(null, false);
          }
        });
      });
    };

    GitManager.prototype.removeUserFromRepos = function(username, gitname, cb) {
      var pid, project, uid,
        _this = this;
      assert.func(cb);
      this.getUidByUsername(username, function() {
        uid = arguments[0];
        _this.getPidByGitname(gitname, function() {
          pid = arguments[0];
          if (pid && uid) {
            _this.gitlab.projects.members.remove(pid, uid, function() {
              project = arguments[0];
              return cb(null, true);
            });
          } else {
            return cb(null, false);
          }
        });
      });
    };

    GitManager.prototype.checkoutReposTo = function(name, directory, cb) {
      return assert.func(cb);
    };

    return GitManager;

  })();

  module.exports = GitManager;

  if (require.main === module) {
    gm = new GitManager;
    testGetProjects = function() {
      var project, projects,
        _this = this;
      gm.getProjects_(function() {
        var _i, _len, _results;
        projects = arguments[0];
        _results = [];
        for (_i = 0, _len = projects.length; _i < _len; _i++) {
          project = projects[_i];
          _results.push(console.log(project.name));
        }
        return _results;
      });
    };
    testHasRepos = function() {
      var err, has,
        _this = this;
      gm.hasRepos("gg", function() {
        err = arguments[0], has = arguments[1];
        return console.log(has);
      });
    };
    testInitRepos = function() {
      var err, url,
        _this = this;
      gm.initRepos("gg", function() {
        err = arguments[0], url = arguments[1];
        return console.log(url);
      });
    };
    testRemoveRepos = function() {
      var err, success,
        _this = this;
      gm.removeRepos("deploy", function() {
        err = arguments[0], success = arguments[1];
        return console.log(success);
      });
    };
    testRemoveRepos();
    testGetModuleNames = function() {
      var err, list,
        _this = this;
      gm.getModuleNames(function() {
        err = arguments[0], list = arguments[1];
        return console.log(list);
      });
    };
    testGetUrlByModuleName = function() {
      var err, url,
        _this = this;
      gm.getUrlByModuleName("gg", function() {
        err = arguments[0], url = arguments[1];
        return console.log(url);
      });
    };
    testGetUrlsByModuleNames = function() {
      var err, list,
        _this = this;
      gm.getUrlsByModuleNames(["gg", 'a'], function() {
        err = arguments[0], list = arguments[1];
        return console.log(list);
      });
    };
    testAddUserToRepos = function() {
      var err, success,
        _this = this;
      gm.addUserToRepos("lixinwei", 'gg', function() {
        err = arguments[0], success = arguments[1];
        return console.log(success);
      });
    };
    testRemoveUserFromRepos = function() {
      var err, success,
        _this = this;
      gm.removeUserFromRepos("lixinwei", 'gg', function() {
        err = arguments[0], success = arguments[1];
        return console.log(success);
      });
    };
  }

}).call(this);
