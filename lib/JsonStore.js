// Generated by ToffeeScript 1.6.3-2
var JsonStore, conf, fs;

fs = require("fs");

JsonStore = (function() {
  JsonStore.prototype.json = null;

  JsonStore.prototype.isNew = null;

  function JsonStore(filename) {
    this.filename = filename;
    this.reload();
  }

  JsonStore.prototype.reload = function() {
    var exist;
    exist = fs.existsSync(this.filename);
    if (!exist) {
      this.json = {};
      return this.isNew = true;
    } else {
      this.json = require(this.filename);
      return this.isNew = false;
    }
  };

  JsonStore.prototype.save = function() {
    return fs.writeFileSync(this.filename, JSON.stringify(this.json), {
      encoding: "utf8"
    });
  };

  return JsonStore;

})();

if (require.main === module) {
  conf = new JsonStore('./test/cna.json');
  conf.json.def = "abc";
  conf.save();
} else {
  module.exports = JsonStore;
}
