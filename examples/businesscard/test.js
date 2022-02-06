const test = require('tape')
const pdf = require('../../')
const path = require('path')
const fs = require('fs')

test('allows custom html and css', function (t) {
  t.plan(3)

  const template = path.join(__dirname, 'businesscard.html')
  const filename = template.replace('.html', '.pdf')
  let templateHtml = fs.readFileSync(template, 'utf8')

  const image = path.join('file://', __dirname, 'image.png')
  templateHtml = templateHtml.replace('{{image}}', image)

  const options = {
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
