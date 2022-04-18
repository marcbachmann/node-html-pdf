var test = require('tape')
var pdf = require('../../')
var path = require('path')
var fs = require('fs')

test('allows custom html and css', function (t) {
  t.plan(3)

  var template = path.join(__dirname, 'businesscard.html')
  var filename = template.replace('.html', '.pdf')
  var templateHtml = fs.readFileSync(template, 'utf8')

  var image = path.join('file://', __dirname, 'image.png')
  templateHtml = templateHtml.replace('{{image}}', image)

  var options = {
    width: '50mm',
    height: '90mm'
  }

  pdf
  .create(templateHtml, options)
  .toFile(filename, function (err, pdf) {
    t.error(err)
    t.assert(pdf.filename, 'Returns the filename')
    t.assert(fs.existsSync(pdf.filename), 'Saves the file to the desired destination')
  })
})
