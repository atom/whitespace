Whitespace = require './whitespace'

module.exports =
  configDefaults:
    removeTrailingWhitespace: true
    ignoreLeadingWhitespaceOnCurrentLine: true
    ensureSingleTrailingNewline: true

  activate: ->
    @whitespace = new Whitespace()

  deactivate: ->
    @whitespace.destroy()
