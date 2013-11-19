module.exports =
  configDefaults:
    removeTrailingWhitespace: true
    ensureSingleTrailingNewline: true

  activate: ->
    @editorSubscription = atom.project.eachEditSession (editor) ->
      bufferSubscription = editor.getBuffer().on 'will-be-saved', (buffer) ->
        buffer.transact ->
          if atom.config.get('whitespace.removeTrailingWhitespace')
            removeTrailingWhitespace(editor)

          if atom.config.get('whitespace.ensureSingleTrailingNewline')
            ensureSingleTrailingNewline(editor)

      editor.on 'destroyed', -> bufferSubscription.off()

  deactivate: ->
    @editorSubscription.off()

removeTrailingWhitespace = (editor) ->
  editor.getBuffer().scan /[ \t]+$/g, ({match, replace}) ->
    # GFM permits two whitespaces at the end of a line
    unless match[0] is '  ' and editor.getGrammar().scopeName is 'source.gfm'
      replace('')

ensureSingleTrailingNewline = (editor) ->
  buffer = editor.getBuffer()
  if buffer.getLastLine() is ''
    row = buffer.getLastRow() - 1
    buffer.deleteRow(row--) while row and buffer.lineForRow(row) is ''
  else
    selectedBufferRanges = editor.getSelectedBufferRanges()
    buffer.append('\n')
    editor.setSelectedBufferRanges(selectedBufferRanges)
