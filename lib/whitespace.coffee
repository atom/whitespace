{Subscriber} = require 'emissary'

module.exports =
class Whitespace
  Subscriber.includeInto(this)

  constructor: ->
    atom.workspace.eachEditor (editor) =>
      @handleEditorEvents(editor)

  destroy: ->
    @unsubscribe()

  handleEditorEvents: (editor) ->
    @subscribe editor, 'will-be-saved', =>
      editor.transact =>
        if atom.config.get('whitespace.removeTrailingWhitespace')
          @removeTrailingWhitespace(editor)

        if atom.config.get('whitespace.ensureSingleTrailingNewline')
          @ensureSingleTrailingNewline(editor)

    @subscribe editor, 'destroyed', =>
      @unsubscribe(editor)

  removeTrailingWhitespace: (editor) ->
    editor.getBuffer().scan /[ \t]+$/g, ({lineText, match, replace}) ->
      if editor.getGrammar().scopeName is 'source.gfm'
        # GitHub Flavored Markdown permits two spaces at the end of a line
        [whitespace] = match
        replace('') unless whitespace is '  ' and whitespace isnt lineText
      else
        replace('')

  ensureSingleTrailingNewline: (editor) ->
    lastRow = editor.getLastBufferRow()
    lastLine = editor.lineForBufferRow(lastRow)
    if lastLine is ''
      row = lastRow - 1
      while row and editor.lineForBufferRow(row) is ''
        editor.deleteBufferRow(row--)
    else
      selectedBufferRanges = editor.getSelectedBufferRanges()
      editor.appendText('\n')
      editor.setSelectedBufferRanges(selectedBufferRanges)
