Whitespace = require './whitespace'

module.exports =
  configDefaults:
    removeTrailingWhitespace: false
    ignoreWhitespaceOnCurrentLine: true
    ignoreWhitespaceOnlyLines: false
    ensureSingleTrailingNewline: false

  activate: ->
    @whitespace = new Whitespace()

  deactivate: ->
    @whitespace.destroy()
