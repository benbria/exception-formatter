// eslint-disable-next-line no-control-regex
const STRIP_COLORS_RE = /\u001b\[[0-9;]*m/g;

// Strip all ansi colors from a string.
exports.stripColors = function(str) {
    return str.replace(STRIP_COLORS_RE, '');
};
