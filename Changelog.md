0.4.0
=====
- buffer options is removed
- create() method return on second argument, an object (if it could be parsed via JSON.parse(), the default script return an object with .filename and .pages keys), if your custom script return a raw text and cannot be parsed, the raw text will be sent back.

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

