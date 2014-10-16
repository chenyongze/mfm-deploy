/*
 * mfe
 * http://git.mofang.com/
 */

'use strict';

//kernel
var mfe = module.exports = require('./lib/kernel.js');

// 主程序
function main(args) {
    mfe.cli.run(args);
}
module.exports.run = main;
