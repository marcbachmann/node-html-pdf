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

if options.httpHeaders
  page.customHeaders = options.httpHeaders

page.content = json.html
page.viewportSize = vp if vp = options.viewportSize
totalPages = 0


page.onError = (msg, trace) ->
  exit(buildStack('Evaluation - '+ msg, trace))


# Force cleanup after 2 minutes
# Add 2 seconds to make sure master process triggers kill
# before to the phantom process
timeout = (options.timeout || 120000) + 2000
setTimeout ->
  exit('Force timeout')
, timeout


# Returns a hash of HTML content
# ------------------------------
getContent = ->
  page.evaluate ->
    styles = document.querySelectorAll('link,style')
    styles = Array::reduce.call(styles, ((string, node) -> string+node.outerHTML),'')
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


# Creates paper with specified options
# ------------------------------------
createPaper = (options) ->
  paper = border: options.border || '0'

  if options.height && options.width
    paper.width = options.width
    paper.height = options.height
  else
    paper.format = options.format || 'A4'
    paper.orientation = options.orientation || 'portrait'

  paper


# Creates page section
# --------------------
createSection = (content, styles, options) ->
  height: options?.height
  contents: phantom.callback (pageNum, numPages) ->
    (options?.contents || content || '')
      .replace('{{page}}', pageNum)
      .replace('{{pages}}', numPages)+styles


# Creates paper with generated footer & header
# --------------------------------------------
generatePaper = (content, options) ->
  paper = createPaper(options)

  for section in ['header', 'footer']
    if options[section] || content[section]
      paper[section] =
        createSection(content[section], content.styles, options[section])

  paper.header?.height ?= '46mm'
  paper.footer?.height ?= '28mm'

  paper


# Completely load page & end process
# ----------------------------------
page.onLoadFinished = (status) ->
  # The paperSize object must be set at once
  page.paperSize = generatePaper(getContent(), options)

  # Output to parent process
  fileOptions =
    type: options.type || 'pdf'
    quality: options.quality || 75

  filename = options.filename || ("#{options.directory || '/tmp'}/html-pdf-#{system.pid}.#{fileOptions.type}")
  page.render(filename, fileOptions)
  system.stdout.write(JSON.stringify({filename}))

  exit(null)
