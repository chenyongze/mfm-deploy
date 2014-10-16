(function() {
  var GitManager;

  if (false) {
    GitManager = require('./GitManagerLocal');
  } else {
    GitManager = require('./GitManagerImpl');
  }

  module.exports = GitManager;

}).call(this);
