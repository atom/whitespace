/** @babel */

import {CompositeDisposable} from 'atom'

export default class Whitespace {
  constructor () {
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

      'whitespace:save-with-trailing-whitespace': () => {
        let editor = atom.workspace.getActiveTextEditor()

        if (editor) {
          this.ignore = true
          editor.save()
          this.ignore = false
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
    let buffer = editor.getBuffer()

    let bufferSavedSubscription = buffer.onWillSave(() => {
      return buffer.transact(() => {
        let scopeDescriptor = editor.getRootScopeDescriptor()

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
    })

    this.subscriptions.add(bufferSavedSubscription)
    this.subscriptions.add(editorTextInsertedSubscription)
    this.subscriptions.add(editorDestroyedSubscription)
  }

  removeTrailingWhitespace (editor, grammarScopeName) {
    let buffer = editor.getBuffer()
    let scopeDescriptor = editor.getRootScopeDescriptor()

    let ignoreCurrentLine = atom.config.get('whitespace.ignoreWhitespaceOnCurrentLine', {
      scope: scopeDescriptor
    })

    let ignoreWhitespaceOnlyLines = atom.config.get('whitespace.ignoreWhitespaceOnlyLines', {
      scope: scopeDescriptor
    })

    return buffer.backwardsScan(/[ \t]+$/g, function ({lineText, match, replace}) {
      let whitespaceRow = buffer.positionForCharacterIndex(match.index).row

      let cursorRows = editor.getCursors().map(cursor => {
        return cursor.getBufferRow()
      })

      if (ignoreCurrentLine && cursorRows.includes(whitespaceRow)) {
        return
      }

      let [whitespace] = match

      if (ignoreWhitespaceOnlyLines && whitespace === lineText) {
        return
      }

      if (grammarScopeName === 'source.gfm' && atom.config.get('whitespace.keepMarkdownLineBreakWhitespace')) {
        if (!(whitespace.length >= 2 && whitespace !== lineText)) {
          return replace('')
        }
      } else {
        return replace('')
      }
    })
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
