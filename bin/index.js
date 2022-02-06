#!/usr/bin/env node

const fs = require('fs')
const pdf = require('../')
const path = require('path')

const args = process.argv.slice(2)

if (args.length >= 2) {
  htmlpdf(args[0], args[1])
} else {
  help()
}

function help () {
  const help = [
    'Usage: html-pdf <source> <destination>',
    'e.g.: html-pdf source.html destination.pdf'
  ].join('\n')

  console.log(help)
}

function htmlpdf (source, destination) {
  const html = fs.readFileSync(source, 'utf8')
  const options = {
    base: 'file://' + path.resolve(source)
  }
  pdf.create(html, options).toFile(destination, function (err, res) {
    if (err) throw err
  })
}
