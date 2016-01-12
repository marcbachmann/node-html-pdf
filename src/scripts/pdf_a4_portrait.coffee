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

if options.base
  page.setContent(json.html, options.base)
else
  page.setContent(json.html, null)

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
    getElements = (doc, wildcard) ->
      wildcardMatcher = new RegExp("#{wildcard}(.*)")
      hasElements = false
      elements = {}
      $elements = document.querySelectorAll("[id*='#{wildcard}']")
      for $elem in $elements
        if match = $elem.attributes.id.value.match(wildcardMatcher)
          hasElements = true
          i = match[1]
          elements[i] = $elem.outerHTML

          $elem.parentNode.removeChild($elem)

      if hasElements
        return elements

    getElement = (doc, id) ->
      if $elem = doc.getElementById(id)
        html = $elem.outerHTML
        $elem.parentNode.removeChild($elem)
        return html

    styles = document.querySelectorAll('link,style')
    styles = Array::reduce.call(styles, ((string, node) -> string+node.outerHTML),'')

    # Wildcard headers e.g. <div id="pageHeader-first"> or <div id="pageHeader-0">
    header = getElements(document, 'pageHeader-')
    footer = getElements(document, 'pageFooter-')

    # Default header and footer e.g. <div id="pageHeader">
    h = getElement(document, 'pageHeader')
    f = getElement(document, 'pageFooter')
    (header ?= {}).default = h if h
    (footer ?= {}).default = f if f

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
createSection = (section, content, options) ->
  c = content[section] || {}
  o = options[section] || {}

  height: o.height
  contents: phantom.callback (pageNum, numPages) ->
    html = c[pageNum]
    html ?= c['first'] if pageNum == 1
    html ?= c['last'] if pageNum == numPages
    (html || c.default || o.contents || '')
      .replace('{{page}}', pageNum)
      .replace('{{pages}}', numPages) + content.styles


# Creates paper with generated footer & header
# --------------------------------------------
generatePaper = (content, options) ->
  paper = createPaper(options)

  for section in ['header', 'footer']
    if options[section] || content[section]
      paper[section] = createSection(section, content, options)

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
