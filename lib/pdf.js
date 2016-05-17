var fs = require('fs');
var childprocess = require('child_process');
var path = require('path');
var assert = require('assert');

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
module.exports = PDF;
function PDF (html, options) {
  this.html = html;
  this.options = options || {};
  if (this.options.script) {
    this.script = path.normalize(this.options.script)
  } else {
    this.script = path.join(__dirname, 'scripts', 'pdf_a4_portrait.js')
  }

  if (this.options.filename) this.options.filename = path.resolve(this.options.filename);
  if (!this.options.phantomPath) this.options.phantomPath = phantomjs && phantomjs.path;
  this.options.phantomArgs = this.options.phantomArgs || [];
  assert(this.options.phantomPath, "html-pdf: Failed to load PhantomJS module. You have to set the path to the PhantomJS binary using 'options.phantomPath'");
  assert(typeof this.html === 'string' && this.html.length, "html-pdf: Can't create a pdf without an html string");
  this.options.timeout = parseInt(this.options.timeout) || 30000
}

PDF.prototype.updateSettings = function UpdateSettings (html, options) {
  PDF.bind(this)(html, options);
};

PDF.prototype.toBuffer = function PdfToBuffer (callback) {
  this.exec(function execPdfToBuffer (err, res) {
    if (err) return callback(err);
    fs.readFile(res.filename, function readCallback (err, buffer) {
      if (err) return callback(err);
      fs.unlink(res.filename, function unlinkPdfFile (err) {
        if (err) return callback(err);
        callback(null, buffer)
      })
    })
  })
};

PDF.prototype.toStream = function PdfToStream (callback) {
  var that = this;

  this.exec(function (err, res) {
    if (err) return callback(err);
    try {
      var stream = fs.createReadStream(res.filename)
    } catch (err) {
      return callback(err)
    } finally {
      that.isLocked = false;
    }

    stream.on('end', function () {
      fs.unlink(res.filename, function (err) {
        if (err) console.log('html-pdf:', err)
      })
    });

    callback(null, stream)
  })
};

PDF.prototype.toFile = function PdfToFile (filename, callback) {
  assert(arguments.length > 0, 'html-pdf: The method .toFile([filename, ]callback) requires a callback.');
  if (filename instanceof Function) {
    callback = filename;
    filename = undefined
  } else {
    this.options.filename = path.resolve(filename)
  }
  this.exec(callback)
};

PDF.prototype.exec = function PdfExec (callback) {
  var that = this;

  if (!that.child) {
    that.child = childprocess.spawn(that.options.phantomPath, [].concat(that.options.phantomArgs, [that.script]));
    that.stderr = [];
  }

  that.onStdoutData && that.child.stdout.removeListener('data', that.onStdoutData);
  that.onStdoutData = onStdoutData.bind(null, callback);
  that.child.stdout.on('data', that.onStdoutData);
  function onStdoutData(callback, buffer) {
    var buff = buffer.toString();
    var data = (buff) != null ? buff.trim() : undefined;
    data = JSON.parse(data);
    if (data.event === 'onLoadFinished') {
      return callback(null, data);
    }
    return buffer;
  }

  that.child.stderr.on('data', onStderrData);
  function onStderrData(buffer) {
    that.stderr.push(buffer);
    that.child.stdin.end();
    return that.child.kill();
  }

  that.child.on('exit', onExit);
  function onExit(code) {
    clearTimeout(that.timeoutExit);
    that.onStdoutData && that.child && that.child.stdout.removeListener('data', that.onStdoutData);
    that.child = null;
    that.isLocked = false;
    if (code || that.stderr.length) {
      var err = new Error(Buffer.concat(that.stderr).toString() || 'html-pdf: Unknown Error');
      that.stderr = [];
      return callback(err)
    }
    that.stderr = [];
  }

  clearTimeout(that.timeoutExit);
  that.timeoutExit = setTimeout(function() {
    that.child.stdin.end();
    that.child.kill();
  }, that.options.timeout);

  console.log('------------------------------------------------------------');
  //console.log(that.html);

  var res = JSON.stringify({ html: that.html, options: that.options });
  that.child.stdin.write(res + '\n', 'utf8');
};
