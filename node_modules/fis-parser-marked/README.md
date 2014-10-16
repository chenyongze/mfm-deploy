# fis-parser-markdown

A parser plugin for fis to compile markdown file.

## usage

    $ npm install -g fis-parser-markdown
    $ vi path/to/project/fis-conf.js

```javascript
//file : path/to/project/fis-conf.js
fis.config.merge({
    roadmap : {
        ext : {
            md : 'html'
        }
    },
    modules : {
        parser : {
            md : 'marked'
        }
    }
});
```