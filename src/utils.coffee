# Strip all ansi colors from a string.
exports.stripColors = (str) ->
    re = /\u001b\[[0-9;]*m/g
    return str.replace re, ''
