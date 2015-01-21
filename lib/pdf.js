var PDF, assert, childprocess, fs, path, phantomjs;

fs = require('fs');

childprocess = require('child_process');

path = require('path');

assert = require('assert');

phantomjs = require('phantomjs');

module.exports = PDF = (function() {
  function PDF(html, options) {
    var _ref;
    this.html = html;
    this.options = options != null ? options : {};
    if (this.options.script) {
      this.script = path.normalize(this.options.script);
    } else {
      this.script = path.join(__dirname, 'scripts', 'pdf_a4_portrait.coffee');
    }
    if (this.options.filename) {
      this.options.filename = path.resolve(this.options.filename);
    }
    assert((_ref = this.html) != null ? _ref.length : void 0, "html-pdf: Can't create a pdf without content");
  }

  PDF.prototype.toBuffer = function(callback) {
    return this.exec(function(err, res) {
      if (err) {
        return callback(err);
      }
      return fs.readFile(res.filename, callback);
    });
  };

  PDF.prototype.toStream = function() {
    var stream;
    stream = new fs.ReadStream;
    this.exec(function(err, res) {
      if (err) {
        return callback(err);
      }
      return fs.createReadStream(res.filename).pipe(stream);
    });
    return stream;
  };

  PDF.prototype.toFile = function(filename, callback) {
    assert(arguments.length === 2, 'html-pdf: The method pdf.toFile([filename, ]callback) requires two arguments.');
    if (arguments.length === 1) {
      callback = filename;
      filename = void 0;
    } else {
      this.options.filename = filename;
    }
    this.exec(callback);
    return stream;
  };

  PDF.prototype.exec = function(callback) {
    var child, stderr, stdout, timeout;
    child = childprocess.spawn(phantomjs.path, [this.script]);
    stdout = [];
    stderr = [];
    timeout = setTimeout(function() {
      child.stdin.end();
      child.kill();
      if (!stderr.length) {
        return stderr = [new Buffer('html-pdf: PDF generation timeout. Phantom.js script did not exit.')];
      }
    }, parseInt(this.options.timeout) || 30000);
    child.stdout.on('data', function(buffer) {
      return stdout.push(buffer);
    });
    child.stderr.on('data', function(buffer) {
      stderr.push(buffer);
      child.stdin.end();
      return child.kill();
    });
    child.on('exit', function(code) {
      var err, filename, _ref;
      clearTimeout(timeout);
      if (code || stderr.length) {
        err = new Error(Buffer.concat(stderr).toString() || 'html-pdf: Unknown Error');
        return callback(err);
      } else {
        filename = (_ref = Buffer.concat(stdout).toString()) != null ? _ref.trim() : void 0;
        return callback(null, {
          filename: filename
        });
      }
    });
    return child.stdin.write(JSON.stringify({
      html: this.html,
      options: this.options
    }) + '\n', 'utf8');
  };

  return PDF;

})();
