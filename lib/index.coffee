PDF = require('./pdf')

exports.create = (html, options, callback) ->
  if arguments.length == 1
    return new PDF(html)

  if arguments.length == 2 && typeof options != 'function'
    return new PDF(html, options)

  if arguments.length == 2
    callback = options
    options = {}

  try
    pdf = new PDF(html, options)
  catch err
    return callback(err)

  pdf.exec(callback)
