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
    editor = atom.workspace.openSync(filePath)
    buffer = editor.getBuffer()

    waitsForPromise ->
      atom.packages.activatePackage('whitespace')

  it "strips trailing whitespace before an editor saves a buffer", ->
    atom.config.set("whitespace.ensureSingleTrailingNewline", false)

    # works for buffers that are already open when package is initialized
    editor.insertText("foo   \nbar\t   \n\nbaz")
    editor.save()
    expect(editor.getText()).toBe "foo\nbar\n\nbaz"

    # works for buffers that are opened after package is initialized
    editor = atom.project.openSync('sample.txt')
    editor.moveCursorToEndOfLine()
    editor.insertText("           ")

    editor.save()
    expect(editor.getText()).toBe 'Some text.\n'

  describe "when the editor is destroyed", ->
    beforeEach ->
      editor.destroy()

    it "unsubscribes from the buffer", ->
      buffer.setText("foo   \nbar\t   \n\nbaz")
      buffer.save()
      expect(buffer.getText()).toBe "foo   \nbar\t   \n\nbaz"

  it "does not trim trailing whitespace if removeTrailingWhitespace is false", ->
    atom.config.set("whitespace.removeTrailingWhitespace", false)

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

  describe "when 'whitespace.ensureSingleTrailingNewline' is false", ->
    beforeEach ->
      atom.config.set("whitespace.ensureSingleTrailingNewline", false)

    it "does not add trailing newline if ensureSingleTrailingNewline is false", ->
      editor.insertText "no trailing newline"
      editor.save()
      expect(editor.getText()).toBe "no trailing newline"

  describe "GFM whitespace trimming", ->
    beforeEach ->
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
