var fs, path, phantomjs, script, spawn;

fs = require('fs');

spawn = require('child_process').spawn;

path = require('path');

phantomjs = require('phantomjs');

script = path.join(__dirname, 'scripts/pdf_a4_portrait.coffee');

exports.create = function(string, options, callback) {
  var child, stderr, stdout, timeout;
  if (arguments.length === 2) {
    callback = options;
    options = {};
  }
  if (!(string != null ? string.length : void 0)) {
    return callback(new Error("Can't create pdf without content"));
  }
  child = spawn(phantomjs.path, [options.script || script, string.length, JSON.stringify(options)]);
  stdout = [];
  stderr = [];
  timeout = setTimeout(function() {
    child.stdin.end();
    child.kill();
    if (!stderr.length) {
      return stderr = [new Buffer('PDF creation timeout. PDF generation script did not end.')];
    }
  }, parseInt(options.timeout) || 10000);
  child.stdout.on('data', function(buffer) {
    return stdout.push(buffer);
  });
  child.stderr.on('data', function(buffer) {
    stderr.push(buffer);
    child.stdin.end();
    return child.kill();
  });
  child.on('exit', function(code) {
    var error, file, filename, isFile;
    clearTimeout(timeout);
    if ((stderr.length || code) > 0) {
      error = new Error(Buffer.concat(stderr).toString());
      return callback(error);
    }
    file = Buffer.concat(stdout);
    if (isFile = /^\%PDF/.test(file.slice(0, 4).toString())) {
      return callback(null, file);
    } else {
      filename = file.toString();
      return fs.readFile(filename, function(err, buffer) {
        if (err) {
          return callback(err);
        }
        if (!options.filename) {
          return fs.unlink(filename, function(err) {
            return callback(err, buffer);
          });
        } else {
          return callback(err, buffer);
        }
      });
    }
  });
  return child.stdin.write(string, 'utf8');
};
