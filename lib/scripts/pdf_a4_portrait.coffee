sys = require('system')
webpage = require('webpage')

page = webpage.create()
size = sys.args[1]
options = {}
options = JSON.parse(sys.args[2]) if typeof sys.args[2] is 'string'
page.content = sys.stdin.read(size)


# Set up content
content = page.evaluate ->
  if $header = document.getElementById('pageHeader')
    header = $header.outerHTML
    $header.parentNode.removeChild($header)

  if $footer = document.getElementById('pageFooter')
    footer = $footer.outerHTML
    $footer.parentNode.removeChild($footer)

  if $body = document.getElementById('pageContent')
    body = $body.outerHTML
  else
    document.body.outerHTML

  return {
    header:  header || ""
    body: body || ""
    footer: footer || ""
  }


# Set up options
paperSize =
  border: options.border || '0'
  header: if options.header || content.header
    height: options.header?.height || "45mm"
    contents: phantom.callback (pageNum, numPages) ->
      (options.header?.contents || content.header)
        .replace('{{page}}', pageNum)
        .replace('{{pages}}', numPages)

  footer: if options.footer || content.footer
    height: options.footer?.height || "28mm"
    contents: phantom.callback (pageNum, numPages) ->
      (options.footer?.contents || content.footer)
        .replace('{{page}}', pageNum)
        .replace('{{pages}}', numPages)

if options.height && options.width
  paperSize.width = options.width
  paperSize.height = options.height
else
  paperSize.format = options.format || 'A4'
  paperSize.orientation = options.portrait || 'portrait'

page.paperSize = paperSize


# Output to parent process

# Option 1: Output file to stdout
# Not working in Ubuntu 12.04 (at least not in my environment)
if options.buffer
  page.render('/dev/stdout', format: 'pdf')


# Option 2: Output filename to stdout
else
  filename = options.filename || ("#{options.directory || '/tmp'}/phantom-pdf-#{sys.pid}-#{size}.pdf")
  page.render(filename, format: 'pdf')
  sys.stdout.write(filename)


phantom.exit(0)
