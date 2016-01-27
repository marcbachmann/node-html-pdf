1.5.0
=====
You can use tags with ids in your html to get custom headers and footers:
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


1.4.0
=====
- Add `httpHeaders` option.
- Fix loading of remote assets by implementing loadFinish event correctly


1.2.1
=====
- Remove 2 minute force timeout [#40](https://github.com/marcbachmann/node-html-pdf/issues/40)


1.2.0
=====
- Add `options.phantomArgs` option requested in [#22](https://github.com/marcbachmann/node-html-pdf/issues/22)
- Also load CSS of html head in PDF header & footer [#31](https://github.com/marcbachmann/node-html-pdf/issues/31), [#27](https://github.com/marcbachmann/node-html-pdf/issues/27)
- Support iojs by upgrading the phantomjs module to v1.9.16


1.1.0
=====
- From now on options.phantomPath allows you to overwrite the default PhantomJS binary path.


1.0.0
=====
- Catch phantomjs errors [517d307](https://github.com/marcbachmann/node-html-pdf/commit/517d30762e3121f72aa3879e07f5944c05c4d96d)

- new module API [#11](https://github.com/marcbachmann/node-html-pdf/pull/11)
  ```js
  pdf = require('html-pdf')
  pdf.create(html).toFile(filepath, function(err, res){
    console.log(res.filename);
  });

  pdf.create(html).toStream(function(err, stream){
    stream.pipe(fs.createWriteStream('./foo.pdf'));
  });

  pdf.create(html).toBuffer(function(err, buffer){
    console.log('This is a buffer:', Buffer.isBuffer(buffer));
  });
  ```


0.3.0
=====
- Windows support #6
- Deprecate buffer method, always write to file from the phantom process #6


0.2.1
=====
- Support `<style></style>` in html head. It will be included in head, body & footer of a page.
- Parse options.timeout. You can now pass a string.
- Improved options documentation


0.2.0
=====
- Support remote images in html template


0.1.3
=====
- Update phantomjs node module dependency, some cdn changed


0.1.2
=====
- Update lib/index.js
- Document options in README


0.1.1
=====
- Remove temp file when options.filename is not present
- Update README


0.1.0
=====
- Initial pdf.create function with several options

