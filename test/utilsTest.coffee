colors = require 'colors/safe'
{expect}    = require 'chai'
utils = require '../src/utils'

describe "utils", ->
    describe 'stripColors', ->
        it "should strip colors from a string", ->
            str = colors.red 'test'
            noColorStr = utils.stripColors(str)
            expect(noColorStr).to.equal 'test'
