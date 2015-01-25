fs = require('fs')
Stream = require('stream').Readable
childprocess = require('child_process')
path = require('path')
assert = require('assert')
phantomjs = require('phantomjs')

#
# phantomjs version 1.8.1 and later should work.
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
module.exports = class PDF

  constructor: (@html, @options={}) ->
    if @options.script
      @script = path.normalize(@options.script)
    else
      @script = path.join(__dirname, 'scripts', 'pdf_a4_portrait.js')

    @options.filename = path.resolve(@options.filename) if @options.filename
    assert(typeof @html is 'string' && @html.length, "html-pdf: Can't create a pdf without an html string")


  toBuffer: (callback) ->
    @exec (err, res) ->
      return callback(err) if err
      fs.readFile res.filename, (err, buffer) ->
        return callback(err) if err
        fs.unlink res.filename, (err) ->
          return callback(err) if err
          callback(null, buffer)


  toStream: (callback) ->
    @exec (err, res) ->
      return callback(err) if err
      try
        stream = fs.createReadStream(res.filename)
      catch err
        return callback(err)

      stream.on 'end', -> fs.unlink res.filename, (err) -> console.log('html-pdf:', err) if err
      callback(null, stream)


  toFile: (filename, callback) ->
    assert(arguments.length > 0, 'html-pdf: The method .toFile([filename, ]callback) requires a callback.')
    if filename instanceof Function
      callback = filename
      filename = undefined
    else
      @options.filename = path.resolve(filename)

    @exec(callback)


  exec: (callback) ->
    child = childprocess.spawn(phantomjs.path, [@script])
    stdout = []
    stderr = []

    timeout = setTimeout ->
      child.stdin.end()
      child.kill()
      stderr = [new Buffer('html-pdf: PDF generation timeout. Phantom.js script did not exit.')] unless stderr.length
    , parseInt(@options.timeout) || 30000

    child.stdout.on 'data', (buffer) ->
      stdout.push(buffer)

    child.stderr.on 'data', (buffer) ->
      stderr.push(buffer)
      child.stdin.end()
      child.kill()

    child.on 'exit', (code) ->
      clearTimeout(timeout)
      if code || stderr.length
        err = new Error(Buffer.concat(stderr).toString() or 'html-pdf: Unknown Error')
        return callback(err)
      else
        try
          data = Buffer.concat(stdout).toString()?.trim()
          data = JSON.parse(data)
        catch err
          return callback(err)
        callback(null, data)

    child.stdin.write(JSON.stringify({@html, @options})+'\n', 'utf8')

