/*
 * fis
 * http://fis.baidu.com/
 */

'use strict';

var marked = require('marked');

module.exports = function(content, file, conf){
    marked.setOptions(conf);
    return marked(content);
};