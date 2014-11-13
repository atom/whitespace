Whitespace = require './whitespace'

module.exports =
  config:
    removeTrailingWhitespace:
      type: 'boolean'
      default: true
      scopes:
        '.source.jade':
          default: false
        '.source.gfm':
          default: false
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
