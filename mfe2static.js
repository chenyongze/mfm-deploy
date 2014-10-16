// Generated by ToffeeScript 1.6.3-2
var async, cheerio, fs, fse, mfe2static, path, prettyPrintHtml, program, request;

fs = require('fs');

path = require('path');

fse = require("fs-extra");

program = require("commander");

prettyPrintHtml = require("html").prettyPrint;

request = require("request");

cheerio = require("cheerio");

async = require("async");

mfe2static = {};

function formatHtml(source) {
  return prettyPrintHtml(source, {
    indent_size: 4,
    indent_char: ' ',
    max_char: 1000,
    brace_style: 'expand',
    unformatted: ['bdo', 'em', 'strong', 'dfn', 'code', 'samp', 'kbd', 'var', 'cite', 'abbr', 'acronym', 'q', 'sub', 'sup', 'tt', 'i', 'b', 'big', 'small', 'u', 's', 'strike', 'font', 'ins', 'del', 'pre', 'address', 'dt']
  });
};

function getHtmlContent(url, next) {
  var body, err, options, response,
    _this = this;
  options = {
    url: url,
    encoding: "utf-8",
    headers: {
      'User-Agent': 'zhangzhiwei',
      'Disable-Cache': '1'
    }
  };
  request(options, function() {
    err = arguments[0], response = arguments[1], body = arguments[2];
    if (!err && response.statusCode === 200) {
      return next(null, body);
    } else {
      return next("get html error");
    }
  });
};

function removeBlankLine(t) {
  return t.replace(/^\s*$/g, "");
};

function help() {
  console.log("+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+");
  console.log("mfe2static <URL> <name>");
  return console.log("+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+");
};

function downloadFile(url, main, dir, next) {
  var fileSavePath, filename, options, p, req,
    _this = this;
  options = {
    url: url,
    headers: {
      'User-Agent': 'zhangzhiwei',
      'Disable-Cache': '1'
    }
  };
  p = url;
  if (url.match(/\/\d+x\d+$/)) {
    p = url.replace(/\/\d+x\d+$/, "");
  }
  if (url.match(/\/\d+$/)) {
    p = url.replace(/\/\d+$/, "");
  }
  filename = path.basename(p);
  fileSavePath = "./" + main + "/" + dir + "/" + filename;
  req = request(options, function(err) {
    if (err) {
      return next(err);
    } else {
      return next(null, "./" + dir + "/" + filename);
    }
  });
  return req.pipe(fs.createWriteStream(fileSavePath));
};

mfe2static.run = function(argv) {
  var $, dir, err, html, htmlCnt, imgs, index_file, links, responseBody, scripts, url,
    _this = this;
  if (argv.length !== 4) {
    help();
    process.exit();
  }
  url = argv[2];
  dir = argv[3];
  fse.mkdirsSync(dir);
  fse.mkdirsSync("" + dir + "/css");
  fse.mkdirsSync("" + dir + "/img");
  fse.mkdirsSync("" + dir + "/js");
  index_file = "" + dir + "/index.html";
  getHtmlContent(url, function() {
    err = arguments[0], responseBody = arguments[1];
    if (err) {
      console.log(err);
      process.exit();
    }
    htmlCnt = formatHtml(responseBody);
    $ = cheerio.load(htmlCnt, {
      normalizeWhitespace: false,
      xmlMode: true,
      lowerCaseTags: true
    });
    scripts = $("script");
    async.each(scripts, function(s, next) {
      var jsFilePath, script, src, txt;
      script = $(s);
      src = script.attr("src");
      if (src && src.length) {
        downloadFile(src, dir, "js", function() {
          err = arguments[0], jsFilePath = arguments[1];
          if (err) {
            return next(err);
          } else {
            script.attr("src", jsFilePath);
            return next(null);
          }
        });
      } else {
        txt = script.text();
        if ((/_bd_share_config/g.test(txt)) || (/cnzz_protocol/g.test(txt)) || (/_bdhmProtocol/g.test(txt))) {
          script.remove();
        }
        return next(null);
      }
    }, function() {
      err = arguments[0];
      if (err) {
        console.log(err);
        process.exit();
      }
      links = $("link");
      async.each(links, function(l, next) {
        var cssFilePath, href, link;
        link = $(l);
        if ((link.attr("rel")) !== "stylesheet") {
          return next(null);
        } else {
          href = link.attr("href");
          if (href && href.length) {
            downloadFile(href, dir, "css", function() {
              err = arguments[0], cssFilePath = arguments[1];
              if (err) {
                return next(err);
              } else {
                link.attr("href", cssFilePath);
                return next(null);
              }
            });
          } else {
            return next(null);
          }
        }
      }, function() {
        err = arguments[0];
        if (err) {
          console.log(err);
          process.exit();
        }
        imgs = $("img");
        async.each(imgs, function(i, next) {
          var img, imgFilePath, src;
          img = $(i);
          src = img.attr("src");
          if (src && src.length) {
            downloadFile(src, dir, "img", function() {
              err = arguments[0], imgFilePath = arguments[1];
              if (err) {
                return next(err);
              } else {
                img.attr("src", imgFilePath);
                return next(null);
              }
            });
          } else {
            return next(null);
          }
        }, function() {
          err = arguments[0];
          if (err) {
            console.log(err);
            process.exit();
          }
          html = $.html();
          html = formatHtml(html);
          err = fse.outputFile(index_file, html);
          if (err) {
            console.log(err);
            process.exit();
          }
          return;
        });
      });
    });
  });
};

function main(argv) {
  return mfe2static.run(argv);
};

module.exports.run = main;
