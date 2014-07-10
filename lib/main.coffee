os = require 'os'
Whitespace = require './whitespace'

module.exports =
  configDefaults:
    removeTrailingWhitespace: true
    ignoreWhitespaceOnCurrentLine: true
    ignoreWhitespaceOnlyLines: false
    ensureSingleTrailingNewline: true
    disableForPaths: [os.tmpDir(), os.tmpDir()]

  activate: ->
    @whitespace = new Whitespace()

  deactivate: ->
    @whitespace?.destroy()
    @whitespace = null
