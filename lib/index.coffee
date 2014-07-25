fs = require('fs')
spawn = require('child_process').spawn
path = require('path')
phantomjs = require('phantomjs')

# 
# phantomjs version 1.8.1 and later should work. Ubuntu has some problems when trying to buffer to /dev/stdout
# 
# Create a PDF file out of an html string.
# 
# Regions for the PDF page are:
# 
# - Page Header  -> document.getElementById('pageHeader')
# - Page Content -> document.getElementById('pageContent')
# - Page Footer  -> document.getElementById('pageFooter')
#
# When no #pageContent is available, phantomjs will use document.body as pdf content
script = path.join(__dirname, 'scripts/pdf_a4_portrait.coffee')

exports.create = (string, options, callback) ->
  if arguments.length == 2
    callback = options
    options = {}

  return callback(new Error("Can't create pdf without content")) unless string?.length
  child = spawn(phantomjs.path, [options.script || script, string.length, JSON.stringify(options)])
  stdout = []
  stderr = []

  timeout = setTimeout ->
    child.stdin.end()
    child.kill()
    stderr = [new Buffer('PDF creation timeout. PDF generation script did not end.')] unless stderr.length
  , parseInt(options.timeout) || 10000

  child.stdout.on 'data', (buffer) ->
    stdout.push(buffer)

  child.stderr.on 'data', (buffer) ->
    stderr.push(buffer)
    child.stdin.end()
    child.kill()

  child.on 'exit', (code) ->
    # Clean up the timeout cause the process ended anyways
    clearTimeout(timeout)
    if (stderr.length || code) > 0
      error = new Error(Buffer.concat(stderr).toString())
      return callback(error)

    file = Buffer.concat(stdout)
    if isFile = /^\%PDF/.test(file.slice(0, 4).toString())
      callback(null, file)

    else
      filename = file.toString()
      fs.readFile filename, (err, buffer) ->
        return callback(err) if err

        # Only delete file when options.filename is not defined
        unless options.filename
          fs.unlink filename, (err) ->
            callback(err, buffer)
        else
          callback(err, buffer)

  child.stdin.write(string, 'utf8')
