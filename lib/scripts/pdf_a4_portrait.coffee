sys = require('system')
webpage = require('webpage')

page = webpage.create()
bufferSize = sys.args[1]
options = {}
options = JSON.parse(sys.args[2]) if typeof sys.args[2] is 'string'
page.content = sys.stdin.read(bufferSize)


# Set up content
# --------------
content = page.evaluate ->
  styles = document.querySelector('head style')?.outerHTML || ''
  if $header = document.getElementById('pageHeader')
    header = $header.outerHTML
    $header.parentNode.removeChild($header)

  if $footer = document.getElementById('pageFooter')
    footer = $footer.outerHTML
    $footer.parentNode.removeChild($footer)

  if $body = document.getElementById('pageContent')
    body = $body.outerHTML
  else
    body = document.body.outerHTML

  {styles, header, body, footer}


# Set up paperSize options
# -------------------------
paper = border: options.border || '0'

if options.height && options.width
  paper.width = options.width
  paper.height = options.height
else
  paper.format = options.format || 'A4'
  paper.orientation = options.orientation || 'portrait'


# Generate footer & header
# ------------------------
setContent = (type) ->
  paper[type] =
    height: options[type]?.height
    contents: phantom.callback (pageNum, numPages) ->
      (options[type]?.contents || content[type] || '')
        .replace('{{page}}', pageNum)
        .replace('{{pages}}', numPages)+content.styles

for type in ['header', 'footer']
  setContent(type) if options[type] || content[type]

paper.header?.height ?= '45mm'
paper.footer?.height ?= '28mm'


# The paperSize object must be set at once
# -----------------------------------------
page.paperSize = paper



# Completely load page & end process
# ----------------------------------
page.onLoadFinished = (status) ->
  # Output to parent process
  fileOptions =
    type: options.type || 'pdf'
    quality: options.quality || 75

  # Option 1: Output file to stdout
  # Not working in Ubuntu 12.04 (at least not in my environment)
  if options.buffer
    page.render('/dev/stdout', fileOptions)


  # Option 2: Output filename to stdout
  else
    filename = options.filename || ("#{options.directory || '/tmp'}/html-pdf-#{sys.pid}-#{bufferSize}.#{fileOptions.type}")
    page.render(filename, fileOptions)
    sys.stdout.write(filename)


  phantom.exit(0)
