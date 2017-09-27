var fs = require('fs')
var childprocess = require('child_process')
var path = require('path')
var assert = require('assert')

try {
  var phantomjs = require('phantomjs-prebuilt')
} catch (err) {
  console.log('html-pdf: Failed to load PhantomJS module.', err)
}

/*
* phantomjs version 1.8.1 and later should work.
*
* Create a PDF file out of an html string.
*
* Regions for the PDF page are:
*
* - Page Header  -> document.getElementById('pageHeader')
* - Page Content -> document.getElementById('pageContent')
* - Page Footer  -> document.getElementById('pageFooter')
*
* When no #pageContent is available, phantomjs will use document.body as pdf content
*/
module.exports = PDF
function PDF (html, options) {
  this.html = html
  this.options = options || {}
  if (this.options.script) {
    this.script = path.normalize(this.options.script)
  } else {
    this.script = path.join(__dirname, 'scripts', 'pdf_a4_portrait.js')
  }

  if (this.options.filename) this.options.filename = path.resolve(this.options.filename)
  if (!this.options.phantomPath) this.options.phantomPath = phantomjs && phantomjs.path
  this.options.phantomArgs = this.options.phantomArgs || []
  assert(this.options.phantomPath, "html-pdf: Failed to load PhantomJS module. You have to set the path to the PhantomJS binary using 'options.phantomPath'")
  assert(typeof this.html === 'string' && this.html.length, "html-pdf: Can't create a pdf without an html string")
  this.options.timeout = parseInt(this.options.timeout, 10) || 30000
}

PDF.prototype.toBuffer = function PdfToBuffer (callback) {
  this.exec(function execPdfToBuffer (err, res) {
    if (err) return callback(err)
    fs.readFile(res.filename, function readCallback (err, buffer) {
      if (err) return callback(err)
      fs.unlink(res.filename, function unlinkPdfFile (err) {
        if (err) return callback(err)
        callback(null, buffer)
      })
    })
  })
}

PDF.prototype.toStream = function PdfToStream (callback) {
  this.exec(function (err, res) {
    if (err) return callback(err)
    try {
      var stream = fs.createReadStream(res.filename)
    } catch (err) {
      return callback(err)
    }

    stream.on('end', function () {
      fs.unlink(res.filename, function unlinkPdfFile (err) {
        if (err) console.log('html-pdf:', err)
      })
    })

    callback(null, stream)
  })
}

PDF.prototype.toFile = function PdfToFile (filename, callback) {
  assert(arguments.length > 0, 'html-pdf: The method .toFile([filename, ]callback) requires a callback.')
  if (filename instanceof Function) {
    callback = filename
    filename = undefined
  } else {
    this.options.filename = path.resolve(filename)
  }
  this.exec(callback)
}

PDF.prototype.exec = function PdfExec (callback) {
  var child = childprocess.spawn(this.options.phantomPath, [].concat(this.options.phantomArgs, [this.script]), this.options.childProcessOptions)
  var stderr = []

  var timeout = setTimeout(function execTimeout () {
    respond(null, new Error('html-pdf: PDF generation timeout. Phantom.js script did not exit.'))
  }, this.options.timeout)

  function onError (buffer) {
    stderr.push(buffer)
  }

  function onData (buffer) {
    var result
    try {
      var json = buffer.toString().trim()
      if (json) result = JSON.parse(json)
    } catch (err) {
      // Proxy for debugging purposes
      process.stdout.write(buffer)
    }

    if (result) respond(null, null, result)
  }

  var callbacked = false
  function respond (code, err, data) {
    if (callbacked) return
    callbacked = true
    clearTimeout(timeout)

    // If we don't have an exit code, we kill the process, ignore stderr after this point
    if (code === null) kill(child, onData, onError)

    if (!data) {
      if (!err && code) err = new Error("html-pdf: Received the exit code '" + code + "'")
      else if (!err) err = new Error('html-pdf: Unknown Error')

      var postfix = stderr.length ? '\n' + Buffer.concat(stderr).toString() : ''
      if (postfix) err.message += postfix
      return callback(err, null)
    }

    callback(null, data)
  }

  child.stdout.on('data', onData)
  child.stderr.on('data', onError)
  child.on('error', function onError (err) { respond(null, err) })

  // An exit event is most likely an error because we didn't get any data at this point
  child.on('close', respond)
  child.on('exit', respond)

  var config = JSON.stringify({html: this.html, options: this.options})
  child.stdin.write(config + '\n', 'utf8')
  child.stdin.end()
}

function kill (child, onData, onError) {
  child.stdin.end()
  child.kill()
}
