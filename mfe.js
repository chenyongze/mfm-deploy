var fis = module.exports = require('fis');

fis.cli.name = "mfe";
fis.cli.info = fis.util.readJSON(__dirname + '/package.json');


require("./mfe-conf.js");
require("./mfe-deploy.js");