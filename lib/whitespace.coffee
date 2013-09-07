module.exports =
  configDefaults:
    removeTrailingWhitespace: true
    ensureSingleTrailingNewline: true

  activate: ->
    rootView.eachEditSession (editSession) => @whitespaceBeforeSave(editSession)

  whitespaceBeforeSave: (editSession) ->
    buffer = editSession.buffer
    saveHandler = ->
      buffer.transact ->
        if config.get('whitespace.removeTrailingWhitespace')
          buffer.scan /[ \t]+$/g, ({match, replace}) ->
            # GFM permits two whitespaces at the end of a line--trim anything else
            unless editSession.getGrammar().scopeName is "source.gfm" and match[0] is "  "
              replace('')

        if config.get('whitespace.ensureSingleTrailingNewline')
          if buffer.getLastLine() is ''
            row = buffer.getLastRow() - 1
            while row and buffer.lineForRow(row) is ''
              buffer.deleteRow(row--)
          else
            selectedBufferRanges = editSession.getSelectedBufferRanges()
            buffer.append('\n')
            editSession.setSelectedBufferRanges(selectedBufferRanges)

    buffer.on('will-be-saved', saveHandler)
    editSession.on 'destroyed', -> buffer.off('will-be-saved', saveHandler)
