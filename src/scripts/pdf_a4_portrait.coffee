system = require('system')
webpage = require('webpage')

# Error handler
exit = (error) ->
  message = error if typeof error is 'string'
  system.stderr.write("html-pdf: #{message || "Unknown Error #{error}"}\n") if error
  phantom.exit(if error then 1 else 0)


# Build stack to print
buildStack = (msg, trace) ->
  msgStack = [msg]
  if trace?.length
    msgStack.push('Stack:')
    trace.forEach (t) ->
      msgStack.push("  at #{t.file || t.sourceURL}: #{t.line} (in function #{t.function})")
  msgStack.join('\n')


phantom.onError = (msg, trace) ->
  exit(buildStack('Script - '+ msg, trace))


# Load configurations from stdin
json = JSON.parse(system.stdin.readLine())
exit('Did not receive any html') if !json.html?.trim()

options = json.options
page = webpage.create()
page.content = json.html
page.viewportSize = vp if vp = options.viewportSize
totalPages = 0


page.onError = (msg, trace) ->
  exit(buildStack('Evaluation - '+ msg, trace))


# Force cleanup after 2 minutes
timeout = timeout+2000 if timeout = json.options.timeout
setTimeout ->
  exit('Force timeout')
, timeout || 12000


# Set up content
# --------------
content = page.evaluate ->
  styles = document.querySelectorAll('link,style')
  styles = Array::reduce.call(styles, ((string, node) -> string+node.outerHTML),'')
  if $header = document.getElementById('pageHeader')
    header = $header.outerHTML
    $header.parentNode.removeChild($header)

  if $fpHeader = document.getElementById('firstPageHeader')
    fpHeader = $fpHeader.outerHTML
    $fpHeader.parentNode.removeChild($fpHeader)

  if $footer = document.getElementById('pageFooter')
    footer = $footer.outerHTML
    $footer.parentNode.removeChild($footer)

  if $fpFooter = document.getElementById('firstPageFooter')
    fpFooter = $fpFooter.outerHTML
    $fpFooter.parentNode.removeChild($fpFooter)

  if $body = document.getElementById('pageContent')
    body = $body.outerHTML
  else
    body = document.body.outerHTML

  {styles, header, fpHeader, body, footer, fpFooter}


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
  fpType = 'fp' + type.charAt(0).toUpperCase() + type.slice(1)
  return paper[type] =
    height: options[type]?.height
    contents: phantom.callback (pageNum, numPages) ->
      return (options[fpType]?.contents || content[fpType] || options[type]?.contents || content[type] || '')
        .replace('{{page}}', pageNum)
        .replace('{{pages}}', numPages)+content.styles if pageNum == 1
      return (options[type]?.contents || content[type] || '')
        .replace('{{page}}', pageNum)
        .replace('{{pages}}', numPages)+content.styles if pageNum > 1

for type in ['header', 'footer']
  setContent(type) if options[type] || content[type]

paper.header?.height ?= '46mm'
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

  filename = options.filename || ("#{options.directory || '/tmp'}/html-pdf-#{system.pid}.#{fileOptions.type}")
  page.render(filename, fileOptions)
  system.stdout.write(JSON.stringify({filename}))

  exit(null)
