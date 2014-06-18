path = require 'path'
{Subscriber} = require 'emissary'

module.exports =
class Whitespace
  Subscriber.includeInto(this)

  constructor: ->
    @subscribe atom.workspace.eachEditor (editor) =>
      @handleEvents(editor)

    @subscribe atom.workspaceView.command 'whitespace:remove-trailing-whitespace', =>
      if editor = atom.workspace.getActiveEditor()
        @removeTrailingWhitespace(editor, editor.getGrammar().scopeName)

  destroy: ->
    @unsubscribe()

  handleEvents: (editor) ->
    buffer = editor.getBuffer()
    bufferSavedSubscription = @subscribe buffer, 'will-be-saved', =>
      buffer.transact =>
        if atom.config.get('whitespace.removeTrailingWhitespace') && path.extname(editor.getPath()) not in atom.config.get('whitespace.ignoreFiles').split ", "
          @removeTrailingWhitespace(editor, editor.getGrammar().scopeName)

        if atom.config.get('whitespace.ensureSingleTrailingNewline')
          @ensureSingleTrailingNewline(editor)

    @subscribe editor, 'destroyed', =>
      bufferSavedSubscription.off()
      @unsubscribe(editor)

    @subscribe buffer, 'destroyed', =>
      @unsubscribe(buffer)

  removeTrailingWhitespace: (editor, grammarScopeName) ->
    buffer = editor.getBuffer()
    ignoreCurrentLine = atom.config.get('whitespace.ignoreWhitespaceOnCurrentLine')
    ignoreWhitespaceOnlyLines = atom.config.get('whitespace.ignoreWhitespaceOnlyLines')

    buffer.backwardsScan /[ \t]+$/g, ({lineText, match, replace}) ->
      whitespaceRow = buffer.positionForCharacterIndex(match.index).row
      cursorRows = (cursor.getBufferRow() for cursor in editor.getCursors())

      return if ignoreCurrentLine and whitespaceRow in cursorRows

      [whitespace] = match
      return if ignoreWhitespaceOnlyLines and whitespace is lineText

      if grammarScopeName is 'source.gfm'
        # GitHub Flavored Markdown permits two spaces at the end of a line
        replace('') unless whitespace is '  ' and whitespace isnt lineText
      else
        replace('')

  ensureSingleTrailingNewline: (editor) ->
    buffer = editor.getBuffer()
    lastRow = buffer.getLastRow()

    if buffer.lineForRow(lastRow) is ''
      row = lastRow - 1
      buffer.deleteRow(row--) while row and buffer.lineForRow(row) is ''
    else
      selectedBufferRanges = editor.getSelectedBufferRanges()
      buffer.append('\n')
      editor.setSelectedBufferRanges(selectedBufferRanges)
