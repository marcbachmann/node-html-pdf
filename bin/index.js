#!/usr/bin/env node

var fs = require('fs')
var pdf = require('../')
var path = require('path')
var argv = require('yargs-parser')(process.argv.slice(2), {array: 'phantomArgs'})

if (argv._.length >= 2) {
  htmlpdf(argv._[0], argv._[1])
} else {
  help()
}

function help () {
  var help = [
    'Usage: html-pdf <source> <destination> [options]',
    'e.g.: html-pdf source.html destination.pdf'
  ].join('\n')

  console.log(help)
}

function htmlpdf (source, destination) {
  var html = fs.readFileSync(source, 'utf8')
  if (!argv.base) argv.base = 'file://' + path.resolve(source)
  pdf.create(html, argv).toFile(destination, function (err, res) {
    if (err) throw err
  })
}

