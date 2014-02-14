module.exports =
  configDefaults:
    removeTrailingWhitespace: true
    ensureSingleTrailingNewline: true

  activate: ->
    @editorSubscription = atom.project.eachEditor (editor) ->
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
  editor.getBuffer().scan /[ \t]+$/g, ({lineText, match, replace}) ->
    if editor.getGrammar().scopeName is 'source.gfm'
      # GitHub Flavored Markdown permits two spaces at the end of a line
      [whitespace] = match
      replace('') unless whitespace is '  ' and whitespace isnt lineText
    else
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
