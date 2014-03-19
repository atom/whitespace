Whitespace = require './whitespace'

module.exports =
  configDefaults:
    removeTrailingWhitespace: true
    ignoreWhitespaceOnCurrentLine: true
    ignoreWhitespaceOnlyLines: false
    ensureSingleTrailingNewline: true

  activate: ->
    @whitespace = new Whitespace()

  deactivate: ->
    @whitespace?.destroy()
    @whitespace = null
