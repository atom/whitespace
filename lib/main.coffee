Whitespace = require './whitespace'

module.exports =
  configDefaults:
    removeTrailingWhitespace: true
    ensureSingleTrailingNewline: true

  activate: ->
    @whitespace = new Whitespace()

  deactivate: ->
    @whitespace.destroy()
