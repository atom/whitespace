path = require 'path'
fs = require 'fs-plus'
{WorkspaceView} = require 'atom'
temp = require 'temp'

describe "Whitespace", ->
  [editor, buffer] = []

  beforeEach ->
    directory = temp.mkdirSync()
    atom.project.setPath(directory)
    atom.workspaceView = new WorkspaceView()
    atom.workspace = atom.workspaceView.model
    filePath = path.join(directory, 'atom-whitespace.txt')
    fs.writeFileSync(filePath, '')
    fs.writeFileSync(path.join(directory, 'sample.txt'), 'Some text.\n')

    waitsForPromise ->
      atom.workspace.open(filePath).then (o) -> editor = o

    runs ->
      buffer = editor.getBuffer()

    waitsForPromise ->
      atom.packages.activatePackage('whitespace')

  describe "when the editor is destroyed", ->
    beforeEach ->
      editor.destroy()

    it "unsubscribes from the buffer", ->
      buffer.setText("foo   \nbar\t   \n\nbaz")
      buffer.save()
      expect(buffer.getText()).toBe "foo   \nbar\t   \n\nbaz"

  describe "when 'whitespace.removeTrailingWhitespace' is true", ->
    beforeEach ->
      atom.config.set("whitespace.removeTrailingWhitespace", true)

    it "strips trailing whitespace before an editor saves a buffer", ->
      # works for buffers that are already open when package is initialized
      editor.insertText("foo   \nbar\t   \n\nbaz\n")
      editor.save()
      expect(editor.getText()).toBe "foo\nbar\n\nbaz\n"

      waitsForPromise ->
        # works for buffers that are opened after package is initialized
        editor = atom.workspace.open('sample.txt').then (o) -> editor = o

      runs ->
        editor.moveCursorToEndOfLine()
        editor.insertText("           ")

        # move cursor to next line to avoid ignoreWhitespaceOnCurrentLine
        editor.moveCursorToBottom()

        editor.save()
        expect(editor.getText()).toBe 'Some text.\n'

  describe "when 'whitespace.removeTrailingWhitespace' is false", ->
    beforeEach ->
      atom.config.set("whitespace.removeTrailingWhitespace", false)

    it "does not trim trailing whitespace", ->
      editor.insertText "don't trim me "
      editor.save()
      expect(editor.getText()).toBe "don't trim me \n"

  describe "when 'whitespace.ignoreWhitespaceOnCurrentLine' is true", ->
    beforeEach ->
      atom.config.set("whitespace.ignoreWhitespaceOnCurrentLine", true)

    it "removes the whitespace from all lines, excluding the current lines", ->
      editor.insertText "1  \n2  \n3  \n"
      editor.setCursorBufferPosition([1,3])
      editor.addCursorAtBufferPosition([2,3])
      editor.save()
      expect(editor.getText()).toBe "1\n2  \n3  \n"

  describe "when 'whitespace.ignoreWhitespaceOnCurrentLine' is false", ->
    beforeEach ->
      atom.config.set("whitespace.ignoreWhitespaceOnCurrentLine", false)

    it "removes the whitespace from all lines, including the current lines", ->
      editor.insertText "1  \n2  \n3  \n"
      editor.setCursorBufferPosition([1,3])
      editor.addCursorAtBufferPosition([2,3])
      editor.save()
      expect(editor.getText()).toBe "1\n2\n3\n"

  describe "when 'whitespace.ignoreWhitespaceOnlyLines' is false", ->
    beforeEach ->
      atom.config.set("whitespace.ignoreWhitespaceOnlyLines", false)

    it "removes the whitespace from all lines, including the whitespace-only lines", ->
      editor.insertText "1  \n2\t  \n\t \n3\n"

      # move cursor to bottom for preventing effect of whitespace.ignoreWhitespaceOnCurrentLine
      editor.moveCursorToBottom()
      editor.save()
      expect(editor.getText()).toBe "1\n2\n\n3\n"

  describe "when 'whitespace.ignoreWhitespaceOnlyLines' is true", ->
    beforeEach ->
      atom.config.set("whitespace.ignoreWhitespaceOnlyLines", true)

    it "removes the wthiespace from all lines, excluding the whitespace-only lines", ->
      editor.insertText "1  \n2\t  \n\t \n3\n"

      # move cursor to bottom for preventing effect of whitespace.ignoreWhitespaceOnCurrentLine
      editor.moveCursorToBottom()
      editor.save()
      expect(editor.getText()).toBe "1\n2\n\t \n3\n"

  describe "when 'whitespace.ensureSingleTrailingNewline' is true", ->
    beforeEach ->
      atom.config.set("whitespace.ensureSingleTrailingNewline", true)

    it "adds a trailing newline when there is no trailing newline", ->
      editor.insertText "foo"
      editor.save()
      expect(editor.getText()).toBe "foo\n"

    it "removes extra trailing newlines and only keeps one", ->
      editor.insertText "foo\n\n\n\n"
      editor.save()
      expect(editor.getText()).toBe "foo\n"

    it "leaves a buffer with a single trailing newline untouched", ->
      editor.insertText "foo\nbar\n"
      editor.save()
      expect(editor.getText()).toBe "foo\nbar\n"

    it "leaves an empty buffer untouched", ->
      editor.insertText ""
      editor.save()
      expect(editor.getText()).toBe ""

    it "leaves a buffer that is a single newline untouched", ->
      editor.insertText "\n"
      editor.save()
      expect(editor.getText()).toBe "\n"

    it "does not move the cursor when the new line is added", ->
      editor.insertText "foo\nboo"
      editor.setCursorBufferPosition([0,3])
      editor.save()
      expect(editor.getText()).toBe "foo\nboo\n"
      expect(editor.getCursorBufferPosition()).toEqual([0,3])

    it "preserves selections when saving on last line", ->
      editor.insertText "foo"
      editor.setCursorBufferPosition([0,0])
      editor.selectToEndOfLine()
      originalSelectionRange = editor.getSelection().getBufferRange()
      editor.save()
      newSelectionRange = editor.getSelection().getBufferRange()
      expect(originalSelectionRange).toEqual(newSelectionRange)

  describe "when 'whitespace.ensureSingleTrailingNewline' is false", ->
    beforeEach ->
      atom.config.set("whitespace.ensureSingleTrailingNewline", false)

    it "does not add trailing newline if ensureSingleTrailingNewline is false", ->
      editor.insertText "no trailing newline"
      editor.save()
      expect(editor.getText()).toBe "no trailing newline"

  describe "GFM whitespace trimming", ->
    beforeEach ->
      atom.config.set("whitespace.ignoreWhitespaceOnCurrentLine", false)

      waitsForPromise ->
        atom.packages.activatePackage("language-gfm")

      runs ->
        editor.setGrammar(atom.syntax.grammarForScopeName("source.gfm"))

    it "trims GFM text with a single space", ->
      editor.insertText "foo \nline break!"
      editor.save()
      expect(editor.getText()).toBe "foo\nline break!\n"

    it "leaves GFM text with double spaces alone", ->
      editor.insertText "foo  \nline break!"
      editor.save()
      expect(editor.getText()).toBe "foo  \nline break!\n"

    it "trims GFM text with a more than two spaces", ->
      editor.insertText "foo   \nline break!"
      editor.save()
      expect(editor.getText()).toBe "foo\nline break!\n"

    it "trims empty lines", ->
      editor.insertText "foo\n  "
      editor.save()
      expect(editor.getText()).toBe "foo\n"

      editor.setText "foo\n "
      editor.save()
      expect(editor.getText()).toBe "foo\n"

    it "respects 'whitespace.ignoreWhitespaceOnCurrentLine' setting", ->
      atom.config.set("whitespace.ignoreWhitespaceOnCurrentLine", true)

      editor.insertText "foo \nline break!"
      editor.setCursorBufferPosition([0,4])
      editor.save()
      expect(editor.getText()).toBe "foo \nline break!\n"

    it "respects 'whitespace.ignoreWhitespaceOnlyLines' setting", ->
      atom.config.set("whitespace.ignoreWhitespaceOnlyLines", true)

      editor.insertText "\t \nline break!"
      editor.save()
      expect(editor.getText()).toBe "\t \nline break!\n"

  describe "when the editor is split", ->
    it "does not throw exceptions when the editor is saved after the split is closed (regression)", ->
      atom.workspaceView.getActivePaneView().trigger 'pane:split-right'
      atom.workspace.getPanes()[0].destroyItems()

      editor = atom.workspace.activePaneItem
      editor.setText('test')
      expect(-> editor.save()).not.toThrow()
      expect(editor.getText()).toBe 'test\n'

  describe "when deactivated", ->
    it "does not remove trailing whitespace from editors opened after deactivation", ->
      atom.config.set("whitespace.removeTrailingWhitespace", true)
      atom.packages.deactivatePackage('whitespace')

      editor.setText("foo \n")
      editor.save()
      expect(editor.getText()).toBe "foo \n"

      waitsForPromise ->
        atom.workspace.open('sample2.txt')

      runs ->
        editor = atom.workspace.getActiveEditor()
        editor.setText("foo \n")
        editor.save()
        expect(editor.getText()).toBe "foo \n"

  describe "when the 'whitespace:remove-trailing-whitespace' command is run", ->
    beforeEach ->
      buffer.setText("foo   \nbar\t   \n\nbaz")

    it "removes the trailing whitespace in the active editor", ->
      atom.workspaceView.trigger 'whitespace:remove-trailing-whitespace'
      expect(buffer.getText()).toBe "foo\nbar\n\nbaz"

    it "does not attempt to remove whitespace when the package is deactivated", ->
      atom.packages.deactivatePackage 'whitespace'
      expect(buffer.getText()).toBe "foo   \nbar\t   \n\nbaz"

  describe "when the 'whitespace:convert-tabs-to-spaces' command is run", ->
    it "removes all \t characters and replaces them with spaces using the configured tab length", ->
      editor.setTabLength(2)
      buffer.setText('\ta\n\t\nb\t\nc\t\td')
      atom.workspaceView.trigger 'whitespace:convert-tabs-to-spaces'
      expect(buffer.getText()).toBe "  a\n  \nb  \nc    d"

      editor.setTabLength(3)
      buffer.setText('\ta\n\t\nb\t\nc\t\td')
      atom.workspaceView.trigger 'whitespace:convert-tabs-to-spaces'
      expect(buffer.getText()).toBe "   a\n   \nb   \nc      d"

  describe "when the 'whitespace:convert-spaces-to-tabs' command is run", ->
    it "removes all space characters and replaces them with hard tabs", ->
      editor.setTabLength(2)
      buffer.setText("  a\n  \nb  \nc    d")
      atom.workspaceView.trigger 'whitespace:convert-spaces-to-tabs'
      expect(buffer.getText()).toBe '\ta\n\t\nb\t\nc\t\td'

      editor.setTabLength(3)
      buffer.setText("   a\n   \nb   \nc      d"
      atom.workspaceView.trigger 'whitespace:convert-spaces-to-tabs'
      expect(buffer.getText()).toBe '\ta\n\t\nb\t\nc\t\td')
