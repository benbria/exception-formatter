[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![Build Status](https://travis-ci.org/benbria/exception-formatter.svg?branch=master)](https://travis-ci.org/benbria/exception-formatter)
[![Coverage Status](https://coveralls.io/repos/benbria/exception-formatter/badge.svg?branch=master&service=github)](https://coveralls.io/github/benbria/exception-formatter?branch=master)

What is it?
===========

`exception-formatter` is an NPM package that takes exceptions or stack traces that would normally look like this:

![](https://github.com/benbria/exception-formatter/blob/master/docs/error.png)

and makes them look like this:

![](https://github.com/benbria/exception-formatter/blob/master/docs/ansi.png)

or, in HTML, like this:

![](https://github.com/benbria/exception-formatter/blob/master/docs/html.png)

Features
========

* Automatically highlights *your* code (as opposed to included modules or node.js system libraries)
  since your code is likely where the problem is.
* Strips leading project paths to make exceptions more readable.
* Can read [longjohn](https://github.com/mattinsler/longjohn) and
  [streamline](https://github.com/Sage/streamlinejs) async stacks.

Installation
============

    npm install --save exception-formatter

Usage
=====

    exceptionFormatter = require('exception-formatter');
    console.log( exceptionFormatter(err, options) );

Where `err` is either an `Error`, a `{stack}` object, or a string containing a stack trace.
`options` is an optional parameter containing the following:

* `options.format`   - one of 'ascii', 'ansi', 'html'.  'ascii' and 'ansi' are identical, except
  that 'ansi' will use ANSI color codes to highlight lines.
* `options.maxLines` - The maximum number of lines to print from the exception.  0 or `null` for
  unlimited (the default.)  `"auto"` to truncate after the last line in your source code.
* `options.basepath` - this is your project's root folder.  If you're writing code in
  src/myFile.js, then this should be `path.resolve(__dirname, '..')`.  This path will be
  stripped from the start of every filename in the exception, and is also used to help
  decide which code is "your code" and which is not.  If this is not provided, then `process.cwd()`
  is used by default.
* `options.basepathReplacement` - String used to replace the `basepath`.  Defaults to "./".
* `options.colors` - (Only for `format = 'ansi'`)  If true (the default) then lines which are
  "your code" will be bolded and colorized.  If false, then lines will only be bolded.
* `options.inlineStyle` - (Only for `format = 'html'`) If this option is true, then each line will
  be styled with inline `style` attributes.  If false, each line will be given a `class` instead
  and you can do your own styling.  Note that inline styline is usually required if you want to
  email an exception, since email clients will generally ignore style sheets.

"Your Code"
===========

`exception-formatter` will mark code as "your code" if it is in `options.basepath`, and if it does
not contain `node_modules` anywhere in it's path.
