# Whitespace package [![Build Status](https://travis-ci.org/atom/whitespace.svg?branch=master)](https://travis-ci.org/atom/whitespace)

Strips trailing whitespace and adds a trailing newline when an editor is saved.

To disable/enable features for a certain language package, you can use 
syntax-scoped properties in your `config.cson`. E.g.

    '.slim.text':
      whitespace: 
        removeTrailingWhitespace: false

You find the `scope` on top of a grammer package's settings view.

Note: for `.source.jade` removing trailing whitespaces is disabled by default.
