const {CompositeDisposable, Point, Range} = require('atom')

const TRAILING_WHITESPACE_REGEX = /[ \t]+(?=\r?$)/g

module.exports = class Whitespace {
  constructor () {
    this.watchedEditors = new WeakSet()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(atom.workspace.observeTextEditors(editor => {
      return this.handleEvents(editor)
    }))

    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'whitespace:remove-trailing-whitespace': () => {
        let editor = atom.workspace.getActiveTextEditor()

        if (editor) {
          this.removeTrailingWhitespace(editor, editor.getGrammar().scopeName)
        }
      },

      'whitespace:save-with-trailing-whitespace': async () => {
        let editor = atom.workspace.getActiveTextEditor()

        if (editor) {
          this.ignore = true
          await editor.save()
          this.ignore = false
        }
      },

      'whitespace:flatten-tabs-after-non-whitespace-character': () => {
        let editor = atom.workspace.getActiveTextEditor()
        if (editor) {
          this.flattenTabsAfterNonWhitespaceCharacter(editor, editor.getGrammar().scopeName)
          editor.save()
        }
      },

      'whitespace:save-without-trailing-whitespace': () => {
        let editor = atom.workspace.getActiveTextEditor()

        if (editor) {
          this.removeTrailingWhitespace(editor, editor.getGrammar().scopeName)
          editor.save()
        }
      },

      'whitespace:convert-tabs-to-spaces': () => {
        let editor = atom.workspace.getActiveTextEditor()

        if (editor) {
          this.convertTabsToSpaces(editor)
        }
      },

      'whitespace:convert-spaces-to-tabs': () => {
        let editor = atom.workspace.getActiveTextEditor()

        if (editor) {
          return this.convertSpacesToTabs(editor)
        }
      },

      'whitespace:convert-all-tabs-to-spaces': () => {
        let editor = atom.workspace.getActiveTextEditor()

        if (editor) {
          return this.convertTabsToSpaces(editor, true)
        }
      }
    }))
  }

  destroy () {
    return this.subscriptions.dispose()
  }

  handleEvents (editor) {
    if (this.watchedEditors.has(editor)) return

    let buffer = editor.getBuffer()

    let bufferSavedSubscription = buffer.onWillSave(() => {
      return buffer.transact(() => {
        let scopeDescriptor = editor.getRootScopeDescriptor()

        if (atom.config.get('whitespace.flattenTabsAfterNonWhitespaceCharacter', {scope: scopeDescriptor})) {
          this.flattenTabsAfterNonWhitespaceCharacter(editor)
        }

        if (atom.config.get('whitespace.removeTrailingWhitespace', {
          scope: scopeDescriptor
        }) && !this.ignore) {
          this.removeTrailingWhitespace(editor, editor.getGrammar().scopeName)
        }

        if (atom.config.get('whitespace.ensureSingleTrailingNewline', {scope: scopeDescriptor})) {
          return this.ensureSingleTrailingNewline(editor)
        }
      })
    })

    let editorTextInsertedSubscription = editor.onDidInsertText(function (event) {
      if (event.text !== '\n') {
        return
      }

      if (!buffer.isRowBlank(event.range.start.row)) {
        return
      }

      let scopeDescriptor = editor.getRootScopeDescriptor()

      if (atom.config.get('whitespace.removeTrailingWhitespace', {
        scope: scopeDescriptor
      })) {
        if (!atom.config.get('whitespace.ignoreWhitespaceOnlyLines', {
          scope: scopeDescriptor
        })) {
          return editor.setIndentationForBufferRow(event.range.start.row, 0)
        }
      }
    })

    let editorDestroyedSubscription = editor.onDidDestroy(() => {
      bufferSavedSubscription.dispose()
      editorTextInsertedSubscription.dispose()
      editorDestroyedSubscription.dispose()
      this.subscriptions.remove(bufferSavedSubscription)
      this.subscriptions.remove(editorTextInsertedSubscription)
      this.subscriptions.remove(editorDestroyedSubscription)
      this.watchedEditors.delete(editor)
    })

    this.subscriptions.add(bufferSavedSubscription)
    this.subscriptions.add(editorTextInsertedSubscription)
    this.subscriptions.add(editorDestroyedSubscription)
    this.watchedEditors.add(editor)
  }

  removeTrailingWhitespace (editor, grammarScopeName) {
    const buffer = editor.getBuffer()
    const scopeDescriptor = editor.getRootScopeDescriptor()

    // When buffer is same buffer of activeEditor's buffer, don't remove
    // trailing WS at activeEditor's cursor line.
    const activeEditor = atom.workspace.getActiveTextEditor()
    const cursorRows =
      activeEditor && activeEditor.getBuffer() === buffer
        ? new Set(activeEditor.getCursors().map(cursor => cursor.getBufferRow()))
        : new Set()

    const ignoreCurrentLine = atom.config.get('whitespace.ignoreWhitespaceOnCurrentLine', {
      scope: scopeDescriptor
    })

    const ignoreWhitespaceOnlyLines = atom.config.get('whitespace.ignoreWhitespaceOnlyLines', {
      scope: scopeDescriptor
    })

    const keepMarkdownLineBreakWhitespace =
      grammarScopeName === 'source.gfm' &&
      atom.config.get('whitespace.keepMarkdownLineBreakWhitespace')

    buffer.transact(() => {
      // TODO - remove this conditional after Atom 1.19 stable is released.
      if (buffer.findAllSync) {
        const ranges = buffer.findAllSync(TRAILING_WHITESPACE_REGEX)
        for (let i = 0, n = ranges.length; i < n; i++) {
          const range = ranges[i]
          const row = range.start.row
          const trailingWhitespaceStart = ranges[i].start.column
          if (ignoreCurrentLine && cursorRows.has(row)) continue
          if (ignoreWhitespaceOnlyLines && trailingWhitespaceStart === 0) continue
          if (keepMarkdownLineBreakWhitespace) {
            const whitespaceLength = range.end.column - range.start.column
            if (trailingWhitespaceStart > 0 && whitespaceLength >= 2) continue
          }
          buffer.delete(ranges[i])
        }
      } else {
        for (let row = 0, lineCount = buffer.getLineCount(); row < lineCount; row++) {
          const line = buffer.lineForRow(row)
          const lastCharacter = line[line.length - 1]
          if (lastCharacter === ' ' || lastCharacter === '\t') {
            const trailingWhitespaceStart = line.search(TRAILING_WHITESPACE_REGEX)
            if (ignoreCurrentLine && cursorRows.has(row)) continue
            if (ignoreWhitespaceOnlyLines && trailingWhitespaceStart === 0) continue
            if (keepMarkdownLineBreakWhitespace) {
              const whitespaceLength = line.length - trailingWhitespaceStart
              if (trailingWhitespaceStart > 0 && whitespaceLength >= 2) continue
            }
            buffer.delete(Range(Point(row, trailingWhitespaceStart), Point(row, line.length)))
          }
        }
      }
    })
  }

  flattenTabsAfterNonWhitespaceCharacter (editor) {
    let selectedRanges = editor.getSelectedBufferRanges()
    let buffer = editor.getBuffer()
    let tabSize = editor.getTabLength()
    let lineCount = buffer.getLineCount()
    let newBuffer = ''
    let newRanges = selectedRanges.map((range) => {
      return new Range(new Point(range.start.row, 0), new Point(range.end.row, 0))
    })
    for (let r = 0; r < lineCount; r++) {
      let line = buffer.lineForRow(r).split('')
      let seenNonWhitespace = false
      let actualIndex = 0
      let selectIndex = 0
      for (let c = 0; c < line.length + 1; c++) {
        let currentChar = line[c]
        let spaceSize = 0
        if (!seenNonWhitespace && [' ', '\t'].indexOf(currentChar) === -1) {
          seenNonWhitespace = true
        }
        if (currentChar === '\t') {
          spaceSize = tabSize - (actualIndex % tabSize)
          actualIndex += spaceSize
          selectIndex += spaceSize
          if (seenNonWhitespace) {
            line[c] = ' '.repeat(spaceSize)
          } else {
            selectIndex -= (spaceSize - 1)
          }
        } else {
          actualIndex++
          selectIndex++
        }
        let selectionIndex = selectIndex - (seenNonWhitespace && currentChar === '\t' ? spaceSize : 1)
        for (let s = 0; s < selectedRanges.length; s++) {
          if (selectedRanges[s].start.row === r && selectedRanges[s].start.column === c) {
            newRanges[s].start.row = selectedRanges[s].start.row
            newRanges[s].start.column = selectionIndex
          }
          if (selectedRanges[s].end.row === r && selectedRanges[s].end.column === c) {
            newRanges[s].end.row = selectedRanges[s].end.row
            newRanges[s].end.column = selectionIndex
          }
        }
      }
      newBuffer += line.join('') + '\n'
    }
    buffer.setText(newBuffer)
    editor.setSelectedBufferRanges(newRanges)
  }

  ensureSingleTrailingNewline (editor) {
    let selectedBufferRanges
    let row
    let buffer = editor.getBuffer()
    let lastRow = buffer.getLastRow()

    if (buffer.lineForRow(lastRow) === '') {
      row = lastRow - 1

      while (row && buffer.lineForRow(row) === '') {
        buffer.deleteRow(row--)
      }
    } else {
      selectedBufferRanges = editor.getSelectedBufferRanges()
      buffer.append('\n')
      editor.setSelectedBufferRanges(selectedBufferRanges)
    }
  }

  convertTabsToSpaces (editor, convertAllTabs) {
    let buffer = editor.getBuffer()
    let spacesText = new Array(editor.getTabLength() + 1).join(' ')
    let regex = (convertAllTabs ? /\t/g : /^\t+/g)

    buffer.transact(function () {
      return buffer.scan(regex, function ({replace}) {
        return replace(spacesText)
      })
    })

    return editor.setSoftTabs(true)
  }

  convertSpacesToTabs (editor) {
    let buffer = editor.getBuffer()
    let scope = editor.getRootScopeDescriptor()
    let fileTabSize = editor.getTabLength()

    let userTabSize = atom.config.get('editor.tabLength', {
      scope: scope
    })

    let regex = new RegExp(' '.repeat(fileTabSize), 'g')

    buffer.transact(function () {
      return buffer.scan(/^[ \t]+/g, function ({matchText, replace}) {
        return replace(matchText.replace(regex, '\t').replace(/[ ]+\t/g, '\t'))
      })
    })

    editor.setSoftTabs(false)

    if (fileTabSize !== userTabSize) {
      return editor.setTabLength(userTabSize)
    }
  }
}
