var test = require('tape')
var tapSpec = require('tap-spec')
function noop (err) { if (err) throw err }

test.createStream()
  .pipe(tapSpec())
  .pipe(process.stdout)

var fs = require('fs')
var path = require('path')
var pdf = require('../')
var html = fs.readFileSync(path.join(__dirname, 'example.html'), 'utf8')

//
// API
//
test('pdf.create(html[, options]) throws an error when executing without html', function (t) {
  t.plan(3)

  t.throws(function () { pdf.create(null) }, 'pdf.create(null)')
  t.throws(function () { pdf.create(undefined) }, 'pdf.create(undefined)')
  t.throws(function () { pdf.create('') }, 'pdf.create("")')
})

test('pdf.create(html[, options], callback) returns error as first cb argument when executing without html', function (t) {
  t.plan(3)

  pdf.create(null, function (error) {
    t.assert(error instanceof Error, 'pdf.create(null, cb)')
  })

  pdf.create(undefined, function (error) {
    t.assert(error instanceof Error, 'pdf.create(undefined, cb)')
  })

  pdf.create('', function (error) {
    t.assert(error instanceof Error, 'pdf.create("", cb)')
  })
})

test('pdf.create(html[, options]).toFile([filename, ]callback)', function (t) {
  t.plan(5)

  pdf.create(html).toFile(function (err, pdf) {
    t.error(err)
    t.assert(typeof pdf.filename === 'string', `toFile(callback) returns {filename: '${pdf.filename}'} as second cb argument`)
    fs.unlink(pdf.filename, noop)
  })

  var file = path.join(__dirname, 'simple.pdf')
  pdf.create(html).toFile(file, function (err, pdf) {
    t.error(err)
    t.assert(pdf.filename === file, `toFile(filename, callback) returns {filename: '${pdf.filename}'} as second cb argument`)
    t.assert(fs.existsSync(file), 'writes the file to the given destination')
  })
})

test('pdf.create(html).toBuffer(callback)', function (t) {
  t.plan(3)

  pdf.create(html).toBuffer(function (err, pdf) {
    t.error(err)
    t.assert(Buffer.isBuffer(pdf), 'toBuffer(callback) returns a buffer instance as second cb argument')
    t.assert(/^\%PDF-1.4/.test(pdf.slice(0, 100).toString()), 'the PDF buffer has a PDF Header')
  })
})

test('pdf.create(html, {directory: "/tmp"}).toBuffer(callback)', function (t) {
  t.plan(2)

  pdf.create(html, {directory: '/tmp'}).toBuffer(function (err, pdf) {
    t.error(err)
    t.assert(Buffer.isBuffer(pdf), 'uses the passed directory as tmp dir')
  })
})

test('pdf.create(html, {renderDelay: 1000}).toBuffer(callback)', function (t) {
  t.plan(2)

  pdf.create(html, {renderDelay: 1000}).toBuffer(function (err, pdf) {
    t.error(err)
    t.assert(Buffer.isBuffer(pdf), 'still returns after renderDelay')
  })
})

test('window.callPhantom renders page', function (t) {
  t.plan(3)

  var callbackHtml = fs.readFileSync(path.join(__dirname, 'callback.html'), 'utf8')
  var file = path.join(__dirname, 'callback.pdf')
  var startTime = new Date().getTime()

  pdf.create(callbackHtml, {renderDelay: 'manual'}).toFile(file, function (err, pdf) {
    var endTime = new Date().getTime()
    t.error(err)

    var time = endTime - startTime
    t.assert(time > 1000 && time < 2000, 'rendered in response to callPhantom')
    t.assert(fs.existsSync(file), 'writes the file to the given destination')
  })
})

test('pdf.create(html[, options]).toStream(callback)', function (t) {
  t.plan(3)

  pdf.create(html).toStream(function (err, stream) {
    t.error(err)
    t.assert(stream instanceof fs.ReadStream, 'toStream(callback) returns a fs.ReadStream as second cb argument')
    var destination = path.join(__dirname, 'streamed.pdf')
    stream.pipe(fs.createWriteStream(destination))
    stream.on('end', function () {
      t.assert(fs.existsSync(destination), 'toStream returns a working readable stream')
      fs.unlink(destination, noop)
    })
  })
})

test('allows invalid phantomPath', function (t) {
  t.plan(3)

  var filename = path.join(__dirname, 'invalid-phantomPath.pdf')

  var options = {
    phantomPath: '/bad/path/to/phantom'
  }

  pdf
  .create(html, options)
  .toFile(filename, function (error, pdf) {
    t.assert(error instanceof Error, 'Returns an error')
    t.equal(error.code, 'ENOENT', 'Error code is ENOENT')
    t.error(pdf, 'PDF does not exist')
  })
})

test('allows custom page and footer options', function (t) {
  t.plan(3)

  var filename = path.join(__dirname, 'custom.pdf')
  var options = {
    width: '3in',
    height: '7in',
    footer: {
      contents: '<b style="color: red">page {{page}} of {{pages}}</b>'
    }
  }

  pdf
  .create(html, options)
  .toFile(filename, function (error, pdf) {
    t.error(error)
    t.assert(pdf.filename === filename, 'Returns the filename from the phantom script')
    t.assert(fs.existsSync(pdf.filename), 'Saves the pdf with a custom page size and footer')
  })
})

test('allows different header and footer for first page', function (t) {
  t.plan(3)

  var enrichedHtml = fs.readFileSync(path.join(__dirname, 'multiple-pages.html'), 'utf8')
  var filename = path.join(__dirname, 'multiple-pages.pdf')
  pdf
  .create(enrichedHtml, {quality: 100})
  .toFile(filename, function (error, pdf) {
    t.error(error)
    t.assert(pdf.filename === filename, 'Returns the filename from the phantom script')
    t.assert(fs.existsSync(pdf.filename), 'Saves the pdf with a custom page size and footer')
  })
})

test('load external css', function (t) {
  t.plan(3)

  var enrichedHtml = fs.readFileSync(path.join(__dirname, 'external-css.html'), 'utf8')
  var filename = path.join(__dirname, 'external-css.pdf')
  pdf
  .create(enrichedHtml)
  .toFile(filename, function (error, pdf) {
    t.error(error)
    t.assert(pdf.filename === filename, 'Returns the filename from the phantom script')
    t.assert(fs.existsSync(pdf.filename), 'Saves the pdf with a custom page size and footer')
  })
})

test('load external js', function (t) {
  t.plan(3)

  var enrichedHtml = fs.readFileSync(path.join(__dirname, 'external-js.html'), 'utf8')
  var filename = path.join(__dirname, 'external-js.pdf')
  pdf
  .create(enrichedHtml, {phantomArgs: ['--ignore-ssl-errors=true']})
  .toFile(filename, function (error, pdf) {
    t.error(error)
    t.assert(pdf.filename === filename, 'Returns the filename from the phantom script')
    t.assert(fs.existsSync(pdf.filename), 'Saves the pdf with a custom page size and footer')
  })
})

test('load with cookies js', function (t) {
  t.plan(3)

  var server = require('http').createServer(function (req, res) {
    res.write(req.headers.cookie)
    res.end()
  })

  server.listen(0, function (err) {
    t.error(err, 'http server for iframe started')

    var port = server.address().port
    var filename = path.join(__dirname, 'cookies.pdf')
    pdf.create(`
      <body>here is an iframe which receives the cookies
        <iframe src="http://localhost:${port}" width="400" height="100"></iframe>
      </body>
    `, {
      httpCookies: [{
        name: 'Valid-Cookie-Name',
        value: 'Valid-Cookie-Value',
        domain: 'localhost',
        path: '/'
      }]
    })
    .toFile(filename, function (error, pdf) {
      server.close()
      t.error(error, 'There must be no render error')
      t.assert(fs.existsSync(pdf.filename), 'Saves the pdf')
    })
  })
})
