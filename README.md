# node-html-pdf
## a HTML to PDF converter that wraps phantomjs
![image](http://public.admintools.ch/gh/html-pdf/businesscard.png)  
[Example Business Card](http://public.admintools.ch/gh/html-pdf/businesscard.pdf)  
 -> [and its Source file](test/businesscard.html)  

[Example Receipt](http://public.admintools.ch/gh/html-pdf/order.pdf)


## Example
```javascript
var fs = require('fs');
var pdf = require('html-pdf');
var html = fs.readFileSync('./test/businesscard.html', 'utf8')
var options = { filename: './businesscard.pdf', format: 'Letter' };

pdf.create(html, options).toFile(function(err, res) {
  if (err) return console.log(err);
  console.log(res); // { filename: '/tmp/html-pdf-8ymPV.pdf' }
});
```

## API

```js
pdf.create(html [, options]).toFile([filepath, ]callback)
pdf.create(html [, options]).toBuffer(callback)
pdf.create(html [, options]).toStream(callback)

// for backwards compatibility
pdf.create(html [, options], callback)

```


## Options
```javascript
config = {

  // Export options
  "directory": "/tmp"        // The directory the file gets written into if not using .toFile(filename, callback). default: '/tmp'

  // Papersize Options: http://phantomjs.org/api/webpage/property/paper-size.html
  "height": "10.5in",        // allowed units: mm, cm, in, px
  "width": "8in",            // allowed units: mm, cm, in, px
  - or -
  "format": "Letter",        // allowed units: A3, A4, A5, Legal, Letter, Tabloid
  "orientation": "portrait", // portrait or landscape

  // Page options
  "border": "0"              // default is 0, units: mm, cm, in, px
  "header": {
    "height": "45mm",
    "contents": '<div style="text-align: center;">Author: Marc Bachmann</div>'
  },
  "footer": {
    "height": "28mm",
    "contents": '<span style="color: #444;">{{page}}</span>/<span>{{pages}}</span>'
  },

  // File options
  "type": "pdf",             // allowed file types: png, jpeg, pdf
  "quality": "75",           // only used for types png & jpeg

  // Script options
  "script": '/url'           // Absolute path to a custom phantomjs script, use the file in lib/scripts as example
  "timeout": 10000           // Timeout that will cancel phantomjs, in milliseconds

}
```

The full options object gets converted to JSON and will get passed to the phantomjs script as third argument.  
There are more options concerning the paperSize, header & footer options inside the phantomjs script.
