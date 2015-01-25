1.0.0
=====
- Catch phantomjs errors [517d307](https://github.com/marcbachmann/node-html-pdf/commit/517d30762e3121f72aa3879e07f5944c05c4d96d)

- new module API [#11](https://github.com/marcbachmann/node-html-pdf/pull/11)
  ```js
  pdf = require('html-pdf')
  pdf.create(html).toFile(filepath, function(err, res){
    console.log(res.filename);
  });

  pdf.create(html).toStream(filepath, function(err, stream){
    steam.pipe(fs.createWriteStream('./foo.pdf'));
  });

  pdf.create(html).toBuffer(filepath, function(err, buffer){
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

