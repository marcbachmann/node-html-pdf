test = require('tape')
tapSpec = require('tap-spec')
test.createStream()
  .pipe(tapSpec())
  .pipe(process.stdout)

fs = require('fs')
path = require('path')
pdf = require('../')
html = fs.readFileSync(path.join(__dirname, 'example.html'), 'utf8')

#
# API
#
test 'pdf.create(html[, options]) throws an error when executing without html', (st) ->
  st.plan(3)

  st.throws ->
    pdf.create(null)
  , 'pdf.create(null)'

  st.throws ->
    pdf.create(undefined)
  , 'pdf.create(undefined)'

  st.throws ->
    pdf.create('')
  , 'pdf.create("")'


test 'pdf.create(html[, options], callback) returns error as first cb argument when executing without html', (st) ->
  st.plan(3)

  pdf.create null, (error) ->
    st.assert(error instanceof Error, 'pdf.create(null, cb)')

  pdf.create undefined, (error) ->
    st.assert(error instanceof Error, 'pdf.create(undefined, cb)')

  pdf.create '', (error) ->
    st.assert(error instanceof Error, 'pdf.create("", cb)')


test 'pdf.create(html[, options]).toFile([filename, ]callback)', (st) ->
  st.plan(5)

  pdf.create(html).toFile (err, pdf) ->
    st.error(err)
    st.assert(typeof pdf.filename == 'string', "toFile(callback) returns {filename: '#{pdf.filename}'} as second cb argument")
    fs.unlink(pdf.filename)

  file = path.join(__dirname, 'simple.pdf')
  pdf.create(html).toFile file, (err, pdf) ->
    st.error(err)
    st.assert(pdf.filename == file, "toFile(filename, callback) returns {filename: '#{pdf.filename}'} as second cb argument")
    st.assert(fs.existsSync(file), 'writes the file to the given destination')


test 'pdf.create(html[, options]).toBuffer(callback)', (st) ->
  st.plan(3)

  pdf.create(html).toBuffer (err, pdf) ->
    st.error(err)
    st.assert(Buffer.isBuffer(pdf), "toBuffer(callback) returns a buffer instance as second cb argument")
    st.assert(/^\%PDF-1.4/.test(pdf.slice(0, 100).toString()), "the PDF buffer has a PDF Header")


test 'pdf.create(html[, options]).toStream(callback)', (st) ->
  st.plan(3)

  stream = pdf.create(html).toStream (err, stream) ->
    st.error(err)
    st.assert(stream instanceof fs.ReadStream, "toStream(callback) returns a fs.ReadStream as second cb argument")
    destination = path.join(__dirname, 'streamed.pdf')
    stream.pipe fs.createWriteStream(destination)
    stream.on 'end', ->
      st.assert(fs.existsSync(destination), 'toStream returns a working readable stream')
      fs.unlink(destination)


#
# Options
#
test 'allows custom html and css', (st) ->
  st.plan(3)

  template = path.join(__dirname, 'businesscard.html')
  filename = template.replace('.html', '.pdf')
  templateHtml =  fs.readFileSync(template, 'utf8')
  options =
    width: '50mm'
    height: '90mm'

  pdf.create(templateHtml, options).toFile filename, (err, pdf) =>
    st.error(err)
    st.assert(pdf.filename, 'Returns the filename')
    st.assert(fs.existsSync(pdf.filename), 'Saves the file to the desired destination')


test 'allows custom page and footer options', (st) ->
  st.plan(3)

  filename = path.join(__dirname, 'custom.pdf')
  options =
    width: '3in'
    height: '7in'
    footer:
      contents: '<b style="color: red">page {{page}} of {{pages}}</b>'

  pdf.create(html, options).toFile filename, (error, pdf) ->
    st.error(error)
    st.assert(pdf.filename == filename, 'Returns the filename from the phantom script')
    st.assert(fs.existsSync(pdf.filename), 'Saves the pdf with a custom page size and footer')


test 'load external css', (st) ->
  st.plan(3)

  enrichedHtml = fs.readFileSync(path.join(__dirname, 'external-css.html'), 'utf8')
  filename = path.join(__dirname, 'external-css.pdf')
  pdf.create(enrichedHtml).toFile filename, (error, pdf) ->
    st.error(error)
    st.assert(pdf.filename == filename, 'Returns the filename from the phantom script')
    st.assert(fs.existsSync(pdf.filename), 'Saves the pdf with a custom page size and footer')
