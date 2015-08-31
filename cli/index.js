#!/usr/bin/env node

var fs = require('fs');
var pdf = require('../');

var args = process.argv.slice(2);

if (args.length >= 2) {
	htmlpdf(args[0], args[1]);
} else {
	help();
}

function help() {
	var help = 'Usage: htmlpdf input.html output.pdf';
	console.log(help);
}

function htmlpdf(input, output) {
	var html = fs.readFileSync(input, 'utf8');

	pdf.create(html).toFile(output, function (err, res) {
		if (err) return console.log(err);
	});
}