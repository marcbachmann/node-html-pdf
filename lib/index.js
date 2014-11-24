var fs, path, phantomjs, script, spawn;

fs = require('fs');

spawn = require('child_process').spawn;

path = require('path');

phantomjs = require('phantomjs');

script = path.join(__dirname, 'scripts', 'pdf_a4_portrait.coffee');

exports.create = function(string, options, callback) {
  var child, content, stderr, stdout, timeout;
  if (arguments.length === 2) {
    callback = options;
    options = {};
  }
  if (!(string != null ? string.length : void 0)) {
    return callback(new Error("html-pdf: Can't create a pdf without content"));
  }
  child = spawn(phantomjs.path, [options.script || script]);
  stdout = [];
  stderr = [];
  timeout = setTimeout(function() {
    child.stdin.end();
    child.kill();
    if (!stderr.length) {
      return stderr = [new Buffer('html-pdf: PDF generation timeout. Phantom.js script did not exit.')];
    }
  }, parseInt(options.timeout) || 30000);
  child.stdout.on('data', function(buffer) {
    return stdout.push(buffer);
  });
  child.stderr.on('data', function(buffer) {
    stderr.push(buffer);
    child.stdin.end();
    return child.kill();
  });
  child.on('exit', function(code) {
    var error, file, filename, isFileBuffer;
    clearTimeout(timeout);
    if ((stderr.length || code) > 0) {
      error = new Error(Buffer.concat(stderr).toString() || 'html-pdf: Unknown Error');
      return callback(error);
    }
    file = Buffer.concat(stdout);
    isFileBuffer = /^\%PDF/.test(file.slice(0, 4).toString());
    if (options.filename) {
      return callback(null, file.toString());
    } else if (!isFileBuffer) {
      filename = file.toString();
      return fs.readFile(filename, function(err, buffer) {
        if (err) {
          return callback(err);
        }
        return fs.unlink(filename, function(err) {
          return callback(err, buffer);
        });
      });
    } else {
      return callback(null, file);
    }
  });
  content = {
    html: string,
    options: options
  };
  return child.stdin.write(JSON.stringify(content) + '\n', 'utf8');
};
