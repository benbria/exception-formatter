const colors = require('colors/safe');
const { expect } = require('chai');
const utils = require('../src/utils');

describe('utils', () =>
    describe('stripColors', () =>
        it('should strip colors from a string', function() {
            const str = colors.red('test');
            const noColorStr = utils.stripColors(str);
            return expect(noColorStr).to.equal('test');
        })));
