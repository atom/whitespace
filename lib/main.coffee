Whitespace = require './whitespace'

module.exports =
  config:
    removeTrailingWhitespace:
      type: 'boolean'
      default: true
      scopes:
        '.source.jade':
          default: false
    keepMarkdownLineBreakWhitespace:
      type: 'boolean'
      default: true
      description: '''
      Markdown uses two or more spaces at the end of a line to signify a line break. Enable this
      option to keep this whitespace, even if other settings would remove it.
      '''
    ignoreWhitespaceOnCurrentLine:
      type: 'boolean'
      default: true
    ignoreWhitespaceOnlyLines:
      type: 'boolean'
      default: false
    ensureSingleTrailingNewline:
      type: 'boolean'
      default: true

  activate: ->
    @whitespace = new Whitespace()

  deactivate: ->
    @whitespace?.destroy()
    @whitespace = null
