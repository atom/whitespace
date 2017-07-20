/** @babel */

import Whitespace from './whitespace'

export default {
  activate () {
    this.whitespace = new Whitespace()
  },

  deactivate () {
    if (this.whitespace) this.whitespace.destroy()
    this.whitespace = null
  },

  consumeSuppressor (suppressor) {
    return this.whitespace.addSuppressor(suppressor)
  }
}
