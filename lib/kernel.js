(function() {
  var GitManager, JsonStore, last, mfe;

  mfe = module.exports = {};

  Object.defineProperty(global, 'mfe', {
    enumerable: true,
    writable: false,
    value: mfe
  });

  last = Date.now();

  mfe.time = function(title) {
    console.log(title + ' : ' + (Date.now() - last) + 'ms');
    return last = Date.now();
  };

  mfe.log = function() {
    return console.log.apply(this, arguments);
  };

  mfe.error = function() {
    return console.error.apply(this, arguments);
  };

  mfe.path = {};

  mfe.path.cli = __dirname + "/..";

  mfe.path.data = mfe.path.cli + "/data";

  mfe.path.templates = mfe.path.cli + "/templates";

  mfe.path.work_dir = process.cwd();

  mfe.defaultModules = ['common', 'modules', 'mfe'];

  JsonStore = require("./JsonStore");

  GitManager = require("./GitManager");

  mfe.user_conf = new JsonStore(mfe.path.data + "/user.json");

  require("./cli");

}).call(this);
