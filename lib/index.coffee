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
script = path.join(__dirname, 'scripts', 'pdf_a4_portrait.coffee')

exports.create = (string, options, callback) ->
  if arguments.length == 2
    callback = options
    options = {}

  return callback(new Error("html-pdf: Can't create a pdf without content")) unless string?.length
  child = spawn(phantomjs.path, [options.script || script])
  stdout = []
  stderr = []

  timeout = setTimeout ->
    child.stdin.end()
    child.kill()
    stderr = [new Buffer('html-pdf: PDF generation timeout. Phantom.js script did not exit.')] unless stderr.length
  , parseInt(options.timeout) || 30000

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
      error = new Error(Buffer.concat(stderr).toString() || 'html-pdf: Unknown Error')
      return callback(error)

    file = Buffer.concat(stdout)
    isFileBuffer = /^\%PDF/.test(file.slice(0, 4).toString())

    if options.filename
      callback(null, file.toString())

    else if !isFileBuffer
      filename = file.toString()
      fs.readFile filename, (err, buffer) ->
        return callback(err) if err
        fs.unlink filename, (err) ->
          callback(err, buffer)

    else
      callback(null, file)


  content =
    html: string
    options: options

  child.stdin.write(JSON.stringify(content)+'\n', 'utf8')
