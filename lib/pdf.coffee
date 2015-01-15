fs = require('fs')
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
      @script = path.join(__dirname, 'scripts', 'pdf_a4_portrait.coffee')

    @options.filename = path.resolve(@options.filename) if @options.filename
    assert(@html?.length, "html-pdf: Can't create a pdf without content")


  toBuffer: (callback) ->
    @exec (err, res) ->
      return callback(err) if err
      fs.readFile(res.filename, callback)


  toStream: ->
    stream = new fs.ReadStream
    @exec (err, res) ->
      return callback(err) if err
      fs.createReadStream(res.filename).pipe(stream)
    stream


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
        filename = Buffer.concat(stdout).toString()?.trim()
        callback(null, {filename})

    child.stdin.write(JSON.stringify({@html, @options})+'\n', 'utf8')

