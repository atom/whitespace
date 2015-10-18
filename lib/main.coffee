Whitespace = require './whitespace'

module.exports =
  config:
    removeTrailingWhitespace:
      type: 'boolean'
      default: true
      scopes:
        '.source.jade':
          default: false
      description: 'Automatically remove whitespace characters at ends of lines when the buffer is saved. To disable/enable for a certain language, use [syntax-scoped properties](https://github.com/atom/whitespace#readme) in your `config.cson`.'
    keepMarkdownLineBreakWhitespace:
      type: 'boolean'
      default: true
      description: 'Markdown uses two or more spaces at the end of a line to signify a line break. Enable this option to keep this whitespace in Markdown files, even if other settings would remove it.'
    ignoreWhitespaceOnCurrentLine:
      type: 'boolean'
      default: true
      description: 'Skip removing trailing whitespace on the line which the cursor is positioned on when the buffer is saved. To disable/enable for a certain language, use [syntax-scoped properties](https://github.com/atom/whitespace#readme) in your `config.cson`.'
    ignoreWhitespaceOnlyLines:
      type: 'boolean'
      default: false
      description: 'Skip removing trailing whitespace on lines which consist only of whitespace characters. To disable/enable for a certain language, use [syntax-scoped properties](https://github.com/atom/whitespace#readme) in your `config.cson`.'
    ensureSingleTrailingNewline:
      type: 'boolean'
      default: true
      description: 'If the buffer doesn\'t end with a newline charcter when it\'s saved, then append one. If it ends with more than one newline, remove all but one. To disable/enable for a certain language, use [syntax-scoped properties](https://github.com/atom/whitespace#readme) in your `config.cson`.'

  activate: ->
    @whitespace = new Whitespace()

  deactivate: ->
    @whitespace?.destroy()
    @whitespace = null
