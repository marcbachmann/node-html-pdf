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
pdf.create(html, { width: '50mm', height: '90mm'}, function(err, buffer) {
  if (err) return console.log(err);
  fs.writeFile('businesscard.pdf', buffer);
});
```

## API
Currently there is only one function
```javascript
var pdf = require('html-pdf');
var callback = function(err, buffer){}
pdf.create(htmlString, options, callback)
```

## Options
`script`: Absolute path to a custom phantomjs script, use the file in lib/scripts as example  
`timeout`: Timeout that will cancel phantomjs, milliseconds as Integer, default: 10000  
`filename`: The file path of the file that will be written. If you want to save the file permanently, you have to pass this option.  
`directory`: The directory path of the file that will be written. default: '/tmp'  

The full options object gets converted to JSON and will get passed to the phantomjs script as third argument.  
There are more options concerning the paperSize, header & footer options inside the phantomjs script.  

## documentations for more available options will follow soon :)  
