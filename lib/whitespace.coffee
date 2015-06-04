{CompositeDisposable} = require 'atom'

module.exports =
class Whitespace
  constructor: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @handleEvents(editor)

    @subscriptions.add atom.commands.add 'atom-workspace',
      'whitespace:remove-trailing-whitespace': =>
        if editor = atom.workspace.getActiveTextEditor()
          @removeTrailingWhitespace(editor, editor.getGrammar().scopeName)
      'whitespace:convert-tabs-to-spaces': =>
        if editor = atom.workspace.getActiveTextEditor()
          @convertTabsToSpaces(editor)
      'whitespace:convert-spaces-to-tabs': =>
        if editor = atom.workspace.getActiveTextEditor()
          @convertSpacesToTabs(editor)

  destroy: ->
    @subscriptions.dispose()

  handleEvents: (editor) ->
    buffer = editor.getBuffer()
    bufferSavedSubscription = buffer.onWillSave =>
      buffer.transact =>
        scopeDescriptor = editor.getRootScopeDescriptor()
        if atom.config.get('whitespace.removeTrailingWhitespace', scope: scopeDescriptor)
          @removeTrailingWhitespace(editor, editor.getGrammar().scopeName)
        if atom.config.get('whitespace.ensureSingleTrailingNewline', scope: scopeDescriptor)
          @ensureSingleTrailingNewline(editor)

    editorDestroyedSubscription = editor.onDidDestroy =>
      bufferSavedSubscription.dispose()
      @subscriptions.remove(bufferSavedSubscription)
      editorDestroyedSubscription.dispose()
      @subscriptions.remove(editorDestroyedSubscription)
    bufferDestroyedSubscription = buffer.onDidDestroy =>
      bufferDestroyedSubscription.dispose()
      @subscriptions.remove(bufferDestroyedSubscription)
      bufferSavedSubscription.dispose()
      @subscriptions.remove(bufferSavedSubscription)

    @subscriptions.add(bufferSavedSubscription)
    @subscriptions.add(editorDestroyedSubscription)
    @subscriptions.add(bufferDestroyedSubscription)

  removeTrailingWhitespace: (editor, grammarScopeName) ->
    buffer = editor.getBuffer()
    scopeDescriptor = editor.getRootScopeDescriptor()
    ignoreCurrentLine = atom.config.get('whitespace.ignoreWhitespaceOnCurrentLine', scope: scopeDescriptor)
    ignoreWhitespaceOnlyLines = atom.config.get('whitespace.ignoreWhitespaceOnlyLines', scope: scopeDescriptor)

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

  convertTabsToSpaces: (editor) ->
    buffer = editor.getBuffer()
    spacesText = new Array(editor.getTabLength() + 1).join(' ')

    buffer.transact ->
      buffer.scan /\t/g, ({replace}) -> replace(spacesText)

  convertSpacesToTabs: (editor) ->
    buffer = editor.getBuffer()
    spacesText = new Array(editor.getTabLength() + 1).join(' ')

    buffer.transact ->
      buffer.scan new RegExp(spacesText, 'g'), ({replace}) -> replace('\t')
