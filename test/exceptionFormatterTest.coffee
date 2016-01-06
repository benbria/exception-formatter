{expect}    = require 'chai'
exceptionFormatter = require '../src/exceptionFormatter'

describe "exceptionFormatter", ->
    it "should format an exception as ASCII` without throwing any exceptions", ->
        exceptionFormatter new Error("foo"), {format: 'ascii'}

    it "should format an exception as ANSI without throwing any exceptions", ->
        exceptionFormatter new Error("foo"), {format: 'ansi'}

    it "should format an exception as HTML without throwing any exceptions", ->
        exceptionFormatter new Error("foo"), {format: 'html'}

    it "should format a stack trace without throwing any exceptions", ->
        exceptionFormatter (new Error("foo")).stack

    it "should correctly format a stack trace as ASCII (and correcty strip the basepath)", ->
        dummyException = """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (/Users/jwalton/project/node_modules/express/x/y.js:21:4)
              at foo (/Users/jwalton/project/src/x/y.coffee:188:19)
              at ReadStream.Readable.push (_stream_readable.js:127:10)
              at TTY.onread (net.js:528:21)
        """
        result = exceptionFormatter dummyException, {format: "ascii", basepath: '/Users/jwalton/project/', basepathReplacement: './'}
        expect(result).to.equal """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (./node_modules/express/x/y.js:21:4)
            * at foo (./src/x/y.coffee:188:19)
              at ReadStream.Readable.push (_stream_readable.js:127:10)
              at TTY.onread (net.js:528:21)
        """

    it "should correctly strip the basepath when the basepath is a regex", ->
        dummyException = """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (/Users/jwalton/project/node_modules/express/x/y.js:21:4)
              at foo (/Users/jwalton/project/src/x/y.coffee:188:19)
              at ReadStream.Readable.push (_stream_readable.js:127:10)
              at TTY.onread (net.js:528:21)
        """
        result = exceptionFormatter dummyException, {format: "ascii", basepath: /\/Users\/jwalton\/project\//, basepathReplacement: './'}
        expect(result).to.equal """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (./node_modules/express/x/y.js:21:4)
            * at foo (./src/x/y.coffee:188:19)
              at ReadStream.Readable.push (_stream_readable.js:127:10)
              at TTY.onread (net.js:528:21)
        """

    it "should correctly limit number of lines", ->
        dummyException = """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (/Users/jwalton/project/node_modules/express/x/y.js:21:4)
              at foo (/Users/jwalton/project/src/x/y.coffee:188:19)
              at ReadStream.Readable.push (_stream_readable.js:127:10)
              at TTY.onread (net.js:528:21)
        """
        result = exceptionFormatter dummyException, {format: "ascii", maxLines: 2, basepath: '/Users/jwalton/project/', basepathReplacement: './'}
        expect(result).to.equal """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (./node_modules/express/x/y.js:21:4)
              [truncated]
        """

    it "should automatically limit number of lines", ->
        dummyException = """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (/Users/jwalton/project/node_modules/express/x/y.js:21:4)
              at foo (/Users/jwalton/project/src/x/y.coffee:188:19)
              at ReadStream.Readable.push (_stream_readable.js:127:10)
              at TTY.onread (net.js:528:21)
        """
        result = exceptionFormatter dummyException, {format: "ascii", maxLines: 'auto', basepath: '/Users/jwalton/project/', basepathReplacement: './'}
        expect(result).to.equal """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (./node_modules/express/x/y.js:21:4)
            * at foo (./src/x/y.coffee:188:19)
              [truncated]
        """

    it "should automatically limit number of lines when none are ours", ->
        dummyException = """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (/Users/jwalton/project/node_modules/express/x/y.js:21:4)
              at foo (/Users/jwalton/project/src/x/y.coffee:188:19)
              at ReadStream.Readable.push (_stream_readable.js:127:10)
              at TTY.onread (net.js:528:21)
        """
        result = exceptionFormatter dummyException, {format: "ascii", maxLines: 'auto', basepath: '/Users/bob/project/', basepathReplacement: './'}
        expect(result).to.equal """
            Error: foo
              at Interface.<anonymous> (/Users/jwalton/.nvm/v0.10.32/lib/node_modules/coffee-script/lib/coffee-script/repl.js:66:9)
              at bar (/Users/jwalton/project/node_modules/express/x/y.js:21:4)
              at foo (/Users/jwalton/project/src/x/y.coffee:188:19)
              at ReadStream.Readable.push (_stream_readable.js:127:10)
              at TTY.onread (net.js:528:21)
        """
