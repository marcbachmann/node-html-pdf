var PDF = require('./pdf');

var pdf = null;
var maxIterations = 5;

module.exports = {
  create: function createPdf (html, options, callback) {
    if (pdf == null) {
      pdf = new PDF(html, options);
      pdf.isLocked = true;
      callback(null, pdf);
    } else {
      asyncGetPdf();
    }

    function asyncGetPdf() {
      if (!pdf.isLocked) {
        pdf.isLocked = true;
        pdf.updateSettings(html, options);
        callback(null, pdf);
        return;
      }
      var iterations = 0;
      var interval = setInterval(function foo() {
        if (iterations > maxIterations) {
          clearInterval(interval);
          return callback('html-pdf: PDF generation timeout. Phantom.js process is used by other thread.');
        }
        else if (!pdf.isLocked && pdf.child) {
          pdf.isLocked = true;
          clearInterval(interval);
          pdf.updateSettings(html, options);
          return callback(null, pdf);
        }
        iterations++;
      }, 1000);
    }

    return pdf;
  }
};
