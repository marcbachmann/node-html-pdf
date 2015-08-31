#!/usr/bin/env node

var fs = require('fs')
var pdf = require('../')

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
  var html = fs.readFileSync(source, 'utf8')
  pdf.create(html).toFile(destination, function (err, res) {
    if (err) throw err
  })
}
