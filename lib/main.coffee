Whitespace = require './whitespace'

module.exports =
  configDefaults:
    removeTrailingWhitespace: true
    ignoreWhitespaceOnCurrentLine: true
    ensureSingleTrailingNewline: true

  activate: ->
    @whitespace = new Whitespace()

  deactivate: ->
    @whitespace.destroy()
