# node-html-pdf
## HTML to PDF converter that uses phantomjs
![image](example/businesscard.png)  
[Example Business Card](example/businesscard.pdf)  
 -> [and its Source file](example/businesscard.html)  

[Example Receipt](http://imgr-static.s3-eu-west-1.amazonaws.com/order.pdf)

## Changelog

Have a look at the releases page: https://github.com/marcbachmann/node-html-pdf/releases

## Installation

Install the html-pdf utility via [npm](http://npmjs.org/):

```
$ npm install -g html-pdf
```

## Command-line example

```
$ html-pdf test/businesscard.html businesscard.pdf
```

## Code example
```javascript
var fs = require('fs');
var pdf = require('html-pdf');
var html = fs.readFileSync('./test/businesscard.html', 'utf8');
var options = { format: 'Letter' };

pdf.create(html, options).toFile('./businesscard.pdf', function(err, res) {
  if (err) return console.log(err);
  console.log(res); // { filename: '/app/businesscard.pdf' }
});
```

## API

```js
var pdf = require('html-pdf');
pdf.create(html).toFile([filepath, ]function(err, res){
  console.log(res.filename);
});

pdf.create(html).toStream(function(err, stream){
  stream.pipe(fs.createWriteStream('./foo.pdf'));
});

pdf.create(html).toBuffer(function(err, buffer){
  console.log('This is a buffer:', Buffer.isBuffer(buffer));
});


// for backwards compatibility
// alias to pdf.create(html[, options]).toBuffer(callback)
pdf.create(html [, options], function(err, buffer){});
```

### Footers and Headers

`html-pdf` can read the header or footer of a page out of the html source. You can either set a default header or footer or overwrite that by appending a page number (1 based index) to the `id="pageHeader"` attribute of a html tag.

You can use any combination of those tags. The library tries to find any element, that contains the `pageHeader` or `pageFooter` id prefix.
```html
<div id="pageHeader">Default header</div>
<div id="pageHeader-first">Header on first page</div>
<div id="pageHeader-2">Header on second page</div>
<div id="pageHeader-3">Header on third page</div>
<div id="pageHeader-last">Header on last page</div>
...
<div id="pageFooter">Default footer</div>
<div id="pageFooter-first">Footer on first page</div>
<div id="pageFooter-2">Footer on second page</div>
<div id="pageFooter-last">Footer on last page</div>
```


## Options
```javascript
config = {

  // Export options
  "directory": "/tmp",       // The directory the file gets written into if not using .toFile(filename, callback). default: '/tmp'

  // Papersize Options: http://phantomjs.org/api/webpage/property/paper-size.html
  "height": "10.5in",        // allowed units: mm, cm, in, px
  "width": "8in",            // allowed units: mm, cm, in, px
  - or -
  "format": "Letter",        // allowed units: A3, A4, A5, Legal, Letter, Tabloid
  "orientation": "portrait", // portrait or landscape

  // Page options
  "border": "0",             // default is 0, units: mm, cm, in, px
  - or -
  "border": {
    "top": "2in",            // default is 0, units: mm, cm, in, px
    "right": "1in",
    "bottom": "2in",
    "left": "1.5in"
  },

  "header": {
    "height": "45mm",
    "contents": '<div style="text-align: center;">Author: Marc Bachmann</div>'
  },
  "footer": {
    "height": "28mm",
    "contents": '<span style="color: #444;">{{page}}</span>/<span>{{pages}}</span>'
  },


  // Rendering options
  "base": "file:///home/www/your-asset-path", // Base path that's used to load files (images, css, js) when they aren't referenced using a host

  // File options
  "type": "pdf",             // allowed file types: png, jpeg, pdf
  "quality": "75",           // only used for types png & jpeg

  // Script options
  "phantomPath": "./node_modules/phantomjs/bin/phantomjs", // PhantomJS binary which should get downloaded automatically
  "phantomArgs": [], // array of strings used as phantomjs args e.g. ["--ignore-ssl-errors=yes"]
  "script": '/url',           // Absolute path to a custom phantomjs script, use the file in lib/scripts as example
  "timeout": 30000,           // Timeout that will cancel phantomjs, in milliseconds

  // HTTP Headers that are used for requests
  "httpHeaders": {
    // e.g.
    "Authorization": "Bearer ACEFAD8C-4B4D-4042-AB30-6C735F5BAC8B"
  }

}
```

The full options object gets converted to JSON and will get passed to the phantomjs script as third argument.  
There are more options concerning the paperSize, header & footer options inside the phantomjs script.
