var PDF;

PDF = require('./pdf');

module.exports = function(html, options, callback) {
  var err, pdf;
  if (arguments.length === 1) {
    return new PDF(html);
  }
  if (arguments.length === 2 && typeof options !== 'function') {
    return new PDF(html, options);
  }
  if (arguments.length === 2) {
    callback = options;
    options = {};
  }
  try {
    pdf = new PDF(html, options);
  } catch (_error) {
    err = _error;
    return callback(err);
  }
  return pdf.exec(callback);
};

module.exports.create = function() {
  return module.exports.apply(void 0, arguments);
};
