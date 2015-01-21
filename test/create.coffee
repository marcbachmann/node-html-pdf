chai = require('chai')
fs = require('fs')
path = require('path')
chai.should()
expect = chai.expect
pdf = require('../')


describe 'pdf.create(string[, options][, callback])', ->
  before ->
    @html =  """
      <html>
        <head></head>
        <body>
          <div id="pageHeader">Header</div>
          <div id="pageContent">Content</div>
          <div id="pageFooter">Footer</div>
        </body>
      </html>
    """

  describe 'throws an error when', ->

    [null, undefined, ''].forEach (val) ->
      it "string is '#{val}'", ->
        expect ->
          pdf.create(val)
        .to.throw(Error)


  describe 'returns error in callback when', ->

    [null, undefined, ''].forEach (val) ->
      it  "string is '#{val}'", (done) ->
        pdf.create val, (error, pdf) ->
          expect(error).to.be.instanceOf(Error)
          expect(pdf).to.be.undefined
          done()


  describe '.toFile([filename, ]callback)', ->

    it 'returns {filename: "pathToFile"}', (done) ->
      pdf.create(@html).exec (error, pdf) =>
        expect(pdf).to.be.an('object')
        expect(pdf.filename).to.be.a('string')
        done()


    it 'saves the pdf to a destination', (done) ->
      file = path.join(__dirname,'simple.pdf')
      pdf.create @html, filename: file, (error, pdf) =>
        expect(fs.existsSync(path.join(__dirname,'simple.pdf'))).to.equal(true)
        done()


  describe '.toBuffer([filename, ]callback)', ->

    it 'returns a pdf buffer', (done) ->
      pdf.create(@html).toBuffer (err, pdf) =>
        expect(Buffer.isBuffer(pdf), 'Expect to be a pdf Buffer').to.be.equal(true)
        expect(/^\%PDF-1.4/.test(pdf.toString()), 'Has a PDF header').to.be.equal(true)
        done()


  it 'works with a custom page size and footer', (done) ->
    options =
      width: '3in'
      height: '7in'
      footer:
        contents: 'Page {{page}} of {{pages}}'

    pdf.create @html, options,(error, pdf) =>
      fs.writeFile(path.join(__dirname,'custom.pdf'), pdf)
      expect(error).to.be.null
      done()


  it 'works with custom html and css', (done) ->
    template = path.join(__dirname,'businesscard.html')
    html =  fs.readFileSync(template, 'utf8')
    options =
      width: '50mm'
      height: '90mm'
      filename: path.join(__dirname,'businesscard.pdf')

    pdf.create html, options,(error, pdf) =>
      expect(error).to.be.null
      expect(fs.existsSync(options.filename), 'Saves the file to the desired destination').to.equal(true)
      done()



  it 'does not throw an error when succeeding', (done) ->
    pdf.create @html, (error, pdf) =>
      expect(error).to.be.null
      done()
