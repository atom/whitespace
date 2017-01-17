# Whitespace package
[![OS X Build Status](https://travis-ci.org/atom/whitespace.svg?branch=master)](https://travis-ci.org/atom/whitespace) [![Windows Build Status](https://ci.appveyor.com/api/projects/status/sf8pdb3ausdk1vtb/branch/master?svg=true)](https://ci.appveyor.com/project/Atom/whitespace/branch/master) [![Dependency Status](https://david-dm.org/atom/whitespace.svg)](https://david-dm.org/atom/whitespace)

Strips trailing whitespace and adds a trailing newline when an editor is saved.

To disable/enable features for a certain language package, you can use syntax-scoped properties in your `config.cson`. E.g.

```coffee
'.slim.text':
  whitespace:
    removeTrailingWhitespace: false
```

You find the `scope` on top of a grammar package's settings view.

Note: for `.source.jade`, `.source.diff`, `.source.pug` and `.source.patch`, removing trailing whitespace is disabled by default.
