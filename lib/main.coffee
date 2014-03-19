Whitespace = require './whitespace'

module.exports =
  configDefaults:
    removeTrailingWhitespace: true
    ignoreWhitespaceOnCurrentLine: true
    ignoreWhitespaceOnlyLines: false
    ensureSingleTrailingNewline: true

  activate: ->
    @whitespace = new Whitespace()
    atom.workspaceView.command 'whitespace:remove-trailing-whitespace', =>
      if @whitespace? and editor = atom.workspace.getActiveEditor()
        @whitespace.removeTrailingWhitespace editor, editor.getGrammar().scopeName


  deactivate: ->
    @whitespace?.destroy()
    @whitespace = null
