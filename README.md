# node-html-pdf
## a HTML to PDF converter for node.js
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
