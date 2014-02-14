module.exports =
class Whitespace
  constructor: ->
    @editorSubscription = atom.workspace.eachEditor (editor) ->
      bufferSubscription = editor.on 'will-be-saved', ->
        editor.transact ->
          if atom.config.get('whitespace.removeTrailingWhitespace')
            removeTrailingWhitespace(editor)

          if atom.config.get('whitespace.ensureSingleTrailingNewline')
            ensureSingleTrailingNewline(editor)

      editor.on 'destroyed', -> bufferSubscription.off()

  destroy: ->
    @editorSubscription.off()

  removeTrailingWhitespace: (editor) ->
    editor.getBuffer().scan /[ \t]+$/g, ({match, replace}) ->
      # GFM permits two whitespaces at the end of a line
      unless match[0] is '  ' and editor.getGrammar().scopeName is 'source.gfm'
        replace('')

  ensureSingleTrailingNewline: (editor) ->
    buffer = editor.getBuffer()
    if buffer.getLastLine() is ''
      row = buffer.getLastRow() - 1
      buffer.deleteRow(row--) while row and buffer.lineForRow(row) is ''
    else
      selectedBufferRanges = editor.getSelectedBufferRanges()
      buffer.append('\n')
      editor.setSelectedBufferRanges(selectedBufferRanges)
