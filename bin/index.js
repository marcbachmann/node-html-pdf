#!/usr/bin/env node

var fs = require('fs')
var pdf = require('../')
var path = require('path')

const createDOMPurify = require('dompurify')
const { JSDOM } = require('jsdom')
const window = new JSDOM('').window
const DOMPurify = createDOMPurify(window)

var args = process.argv.slice(2)

if (args.length >= 2) {
  htmlpdf(args[0], args[1])
} else {
  help()
}

function help () {
  var help = [
    'Usage: html-pdf <source> <destination>',
    'e.g.: html-pdf source.html destination.pdf'
  ].join('\n')

  console.log(help)
}

function htmlpdf (source, destination) {
  var html = DOMPurify.sanitize(fs.readFileSync(source, 'utf8'))
  var options = {
    base: 'file://' + path.resolve(source)
  }
  pdf.create(html, options).toFile(destination, function (err, res) {
    if (err) throw err
  })
}
