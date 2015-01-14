# node-html-pdf
## a HTML to PDF converter that wraps phantomjs
![image](http://public.admintools.ch/gh/html-pdf/businesscard.png)  
[Example Business Card](http://public.admintools.ch/gh/html-pdf/businesscard.pdf)  
 -> [and its Source file](test/businesscard.html)  

[Example Receipt](http://public.admintools.ch/gh/html-pdf/order.pdf)


```javascript
var fs = require('fs');
var pdf = require('./lib');
var html = fs.readFileSync('./test/businesscard.html', 'utf8')
pdf.create(html, { filename: './businesscard.pdf', width: '50mm', height: '90mm'}, function(err, res) {
  if (err) return console.log(err);
  console.log(res);
  /*
    {
      filename: './businesscard.pdf',
      pages: 1
    }
  */
});
```

## API
Currently there is only one function
```javascript
var pdf = require('html-pdf');
var callback = function(err, res){}
pdf.create(htmlString, options, callback)
```

## Options
```javascript
config = {

  // Export options
  "filename": "/tmp/html-pdf-123-123.pdf" // The file path of the file that will be written. If you want to save the file permanently, you have to pass this option.
  "directory": "/tmp"        // The directory the file gets written into if no filename is defined. default: '/tmp' 

  // Papersize Options: http://phantomjs.org/api/webpage/property/paper-size.html
  "height": "",              // allowed units: mm, cm, in, px
  "width": "",               // allowed units: mm, cm, in, px
  - or -
  "format": "A4",            // allowed units: A3, A4, A5, Legal, Letter, Tabloid
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
  script: '/url'           // Absolute path to a custom phantomjs script, use the file in lib/scripts as example
  timeout: 10000           // Timeout that will cancel phantomjs, in milliseconds

}
```

The full options object gets converted to JSON and will get passed to the phantomjs script as third argument.  
There are more options concerning the paperSize, header & footer options inside the phantomjs script.
