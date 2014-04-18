chai = require('chai')
fs = require('fs')
path = require('path')
chai.should()
expect = chai.expect
pdf = require('../')


describe 'html-pdf', ->
  describe '#create()', ->
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

    it 'throws error when passing null', (done) ->
      pdf.create null, (error, pdf) ->
        expect(error).to.be.instanceOf(Error)
        expect(pdf).to.be.undefined
        done()

    it 'throws error when passing undefined', (done) ->
      pdf.create undefined, (error, pdf) ->
        expect(error).to.be.instanceOf(Error)
        expect(pdf).to.be.undefined
        done()

    it 'throws error when passing empty string', (done) ->
      pdf.create '', (error, pdf) ->
        expect(error).to.be.instanceOf(Error)
        expect(pdf).to.be.undefined
        done()

    it 'does not throw an error when succeeding', (done) ->
      pdf.create @html, (error, pdf) =>
        @pdf = pdf
        expect(error).to.be.null
        fs.writeFile(path.join(__dirname,'simple.pdf'), pdf)
        done()

    it 'returns a buffer', ->
      expect(Buffer.isBuffer(@pdf), 'Should be a buffer').to.be.equal(true)


    it 'returns a pdf buffer', ->
      expect(/^\%PDF-1.4/.test(@pdf.toString()), 'Has a PDF header').to.be.equal(true)

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

      pdf.create html, options,(error, pdf) =>
        fs.writeFile(path.join(__dirname,'businesscard.pdf'), pdf)
        expect(error).to.be.null
        done()
