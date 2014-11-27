system = require('system')
webpage = require('webpage')

# Error handler
exit = (error) ->
  message = error if typeof error is 'string'
  system.stderr.write("html-pdf: #{message || "Unknown Error #{error}"}\n") if error
  phantom.exit(if error then 1 else 0)


# Force cleanup after 2 minutes
setTimeout ->
  exit('Force timeout')
, 120000


# Load configurations from stdin
json = JSON.parse(system.stdin.readLine())
exit('Did not receive any html') if !json.html?.trim()

options = json.options
page = webpage.create()
page.content = json.html


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

  if !options.buffer
    filename = options.filename || ("#{options.directory || '/tmp'}/html-pdf-#{system.pid}.#{fileOptions.type}")
    page.render(filename, fileOptions)
    system.stdout.write(filename)

  # Deprecated options.buffer method
  else
    system.stderr.write('html-pdf: options.buffer is deprecated. Because of compatibility issues this method is longer supported.\n')
    page.render('/dev/stdout', fileOptions)


  exit(null)
