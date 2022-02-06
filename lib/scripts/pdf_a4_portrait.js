/* global phantom */
const system = require('system')
const webpage = require('webpage')

// Error handler
function exit (error) {
  let message
  if (typeof error === 'string') message = error
  if (error) system.stderr.write('html-pdf: ' + (message || 'Unknown Error ' + error) + '\n')
  phantom.exit(error ? 1 : 0)
}

// Build stack to print
function buildStack (msg, trace) {
  const msgStack = [msg]
  if (trace && trace.length) {
    msgStack.push('Stack:')
    trace.forEach(function (t) {
      msgStack.push('  at ' + t.file || t.sourceURL + ': ' + t.line + ' (in function ' + t.function + ')')
    })
  }
  return msgStack.join('\n')
}

phantom.onError = function (msg, trace) {
  exit(buildStack('Script - ' + msg, trace))
}

// Load configurations from stdin
const json = JSON.parse(system.stdin.readLine())
if (!json.html || !json.html.trim()) exit('Did not receive any html')

const options = json.options
const page = webpage.create()

// Completely load page & end process
// ----------------------------------
let rendered = false
let renderTimeout

// If renderDelay is manual, then listen for an event and don't automatically render
if (options.renderDelay === 'manual') {
  page.onCallback = function (message) {
    setTimeout(renderNow, 0)
    return message
  }
}

page.onLoadFinished = function () {
  if (options.renderDelay === 'manual') return
  renderTimeout = setTimeout(renderNow, Math.floor(options.renderDelay) || 0)
}

function renderNow () {
  if (rendered) return
  rendered = true
  clearTimeout(renderTimeout)
  page.paperSize = definePaperSize(getContent(page), options)

  const fileOptions = {
    type: options.type || 'pdf',
    quality: options.quality || 75
  }

  const filename = options.filename || (options.directory || '/tmp') + '/html-pdf-' + system.pid + '.' + fileOptions.type
  page.render(filename, fileOptions)

  // Output to parent process
  system.stdout.write(JSON.stringify({ filename }))
  exit(null)
}

// Set Content and begin loading
// -----------------------------
if (options.httpCookies) page.cookies = options.httpCookies
if (options.httpHeaders) page.customHeaders = options.httpHeaders
if (options.viewportSize) page.viewportSize = options.viewportSize
if (options.zoomFactor) page.zoomFactor = options.zoomFactor
if (options.base) page.setContent(json.html, options.base)
else page.setContent(json.html, null)

page.onError = function (msg, trace) {
  exit(buildStack('Evaluation - ' + msg, trace))
}

// Force cleanup after 2 minutes
// Add 2 seconds to make sure master process triggers kill
// before to the phantom process
const timeout = (options.timeout || 120000) + 2000
setTimeout(function () {
  exit('Force timeout')
}, timeout)

// Returns a hash of HTML content
// ------------------------------
function getContent (page) {
  return page.evaluate(function () {
    function getElements (doc, wildcard) {
      const wildcardMatcher = new RegExp(wildcard + '(.*)')
      let hasElements = false
      const elements = {}
      const $elements = document.querySelectorAll("[id*='" + wildcard + "']")

      let $elem, match, i
      const len = $elements.length
      for (i = 0; i < len; i++) {
        $elem = $elements[i]
        match = $elem.attributes.id.value.match(wildcardMatcher)
        if (match) {
          hasElements = true
          elements[match[1]] = $elem.outerHTML
          $elem.parentNode.removeChild($elem)
        }
      }

      if (hasElements) return elements
    }

    function getElement (doc, id) {
      const $elem = doc.getElementById(id)
      if ($elem) {
        const html = $elem.outerHTML
        $elem.parentNode.removeChild($elem)
        return html
      }
    }

    let styles = document.querySelectorAll('link,style')
    styles = Array.prototype.reduce.call(styles, function (string, node) {
      return string + (node.outerHTML || '')
    }, '')

    // Wildcard headers e.g. <div id="pageHeader-first"> or <div id="pageHeader-0">
    let header = getElements(document, 'pageHeader-')
    let footer = getElements(document, 'pageFooter-')

    // Default header and footer e.g. <div id="pageHeader">
    const h = getElement(document, 'pageHeader')
    const f = getElement(document, 'pageFooter')

    if (h) {
      header = header || {}
      header.default = h
    }

    if (f) {
      footer = footer || {}
      footer.default = f
    }

    let body
    const $body = document.getElementById('pageContent')
    if ($body) body = $body.outerHTML
    else body = document.body.outerHTML

    return {
      styles,
      header,
      body,
      footer
    }
  })
}

// Creates page section
// --------------------
function createSection (section, content, options) {
  options = options[section] || {}
  const c = content[section] || {}
  let o = options.contents
  const paginationOffset = Math.floor(options.paginationOffset) || 0

  if (typeof o !== 'object') o = { default: o }

  return {
    height: options.height,
    contents: phantom.callback(function (pageNum, numPages) {
      let html = o[pageNum] || c[pageNum]

      const pageNumFinal = pageNum + paginationOffset
      const numPagesFinal = numPages + paginationOffset

      if (pageNumFinal === 1 && !html) html = o.first || c.first
      if (pageNumFinal === numPages && !html) html = o.last || c.last
      return (html || o.default || c.default || '')
        .replace(/{{page}}/g, pageNumFinal)
        .replace(/{{pages}}/g, numPagesFinal) + content.styles
    })
  }
}

// Creates paper with specified options
// ------------------------------------
function definePaperOrientation (options) {
  const paper = { border: options.border || '0' }

  if (options.height && options.width) {
    paper.width = options.width
    paper.height = options.height
  } else {
    paper.format = options.format || 'A4'
    paper.orientation = options.orientation || 'portrait'
  }

  return paper
}

// Creates paper with generated footer & header
// --------------------------------------------
function definePaperSize (content, options) {
  const paper = definePaperOrientation(options)

  if (options.header || content.header) {
    paper.header = createSection('header', content, options)
  }

  if (options.footer || content.footer) {
    paper.footer = createSection('footer', content, options)
  }

  if (paper.header && paper.header.height === undefined) paper.header.height = '46mm'
  if (paper.footer && paper.footer.height === undefined) paper.footer.height = '28mm'

  return paper
}
