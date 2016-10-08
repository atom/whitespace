Whitespace = require './whitespace'

module.exports =
  activate: ->
    @whitespace = new Whitespace()

  deactivate: ->
    @whitespace?.destroy()
    @whitespace = null
