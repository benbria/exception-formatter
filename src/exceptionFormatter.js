/* eslint-disable wrap-iife */
// Module for pretty-formatting exceptions in HTML and Ascii.
//
// The functions in this module will parse JavaScript exceptions, identify which lines in the
// exception come from your application code (vs. exceptions from other modules in node_modules),
// and then format the exception to look pretty in HTML, or add ANSI color codes for display
// in a terminal.
//
// Example:
//
//     projectRoot = path.resolve(__dirname, "../..")
//
//     exceptionFormatter.formatHtml new Error("foo"), {
//         basepath: projectRoot
//     }
//

const path = require('path');
const colors = require('colors/safe');
const { stripColors } = require('./utils');

// Borrowed from ejs
const escapeHtml = html =>
    String(html)
        .replace(/&(?!\w+;)/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');

// Line Types
const HEADER = 'header';
const SOURCE = 'source';
const OUR_SOURCE = 'our-source';
const UNKNOWN = 'unknown';
const DIVIDER = 'divider';

const HTML_INLINE_STYLES = {
    [OUR_SOURCE]: 'white-space:nowrap; font-weight:bold; color: #800',
    [SOURCE]: 'white-space:nowrap; color: #888',
    [DIVIDER]: 'white-space:nowrap; color: #000',
};

const DIVIDERS = [
    '    <<< async stack >>>', // streamline
    '    <<< raw stack >>>', // streamline
    '---------------------------------------------', // longjohn
];

// Given a line from an exception, returns the {filename, line, column} of the exception, or
// null if the line cannot be parsed.
const STACK_LINE_RE = /(\s*)at\s*([^\s]*)\s*\((.*?):(\d*):(\d*)\)/;
const STACK_LINE_NO_FN_RE = /(\s*)at\s*(.*?):(\d*):(\d*)/;

const isDefined = x => x !== null && x !== undefined;

function parseExceptionLine(line) {
    let match = STACK_LINE_RE.exec(line);
    if (match) {
        return {
            indent: match[1],
            fn: match[2],
            filename: match[3],
            line: match[4],
            column: match[5],
        };
    } else {
        match = STACK_LINE_NO_FN_RE.exec(line);
        if (match) {
            return { indent: match[1], filename: match[2], line: match[3], column: match[4] };
        } else {
            return null;
        }
    }
}

// Parses an exception into lines.
// Returns a collection of {line, type} objects.
//
// This function will call `String.replace(options.basepath, options.basepathReplacement)` on
// every source line.  This can be used to strip the project folder from file pathnames.
// `options.basepathReplacement` defaults to "./" if not specified.
//
function parseException(exception, options = {}) {
    let basepath = isDefined(options.basepath) ? options.basepath : process.cwd();

    // Add a trailing '/' to the basepath if it doesn't have one, because `__dirname` doesn't
    // have one.  Don't add the trailing '/' if it's a regex, because that's crazy talk.  :)
    if (typeof basepath === 'string' && !basepath.endsWith(path.sep)) {
        basepath += path.sep;
    }
    const basepathReplacement = isDefined(options.basepathReplacement)
        ? options.basepathReplacement
        : `.${path.sep}`;

    const exceptionText =
        typeof exception === 'string'
            ? exception
            : isDefined(exception.stack)
            ? exception.stack
            : `${exception}`;

    const value = stripColors(exceptionText);
    const lines = value.split('\n');

    let endOfHeader = false;
    return lines.map(function(line) {
        let filename, type;
        let parsed = null;

        // Figure out what kind of line each line is.
        if (DIVIDERS.includes(line)) {
            endOfHeader = true;
            type = DIVIDER;
        } else {
            parsed = parseExceptionLine(line);
            if (parsed) {
                ({ filename } = parsed);
                endOfHeader = true;
                type = SOURCE;
                if (
                    filename.indexOf('node_modules') === -1 &&
                    filename[typeof basepath === 'string' ? 'indexOf' : 'search'](basepath) !== -1
                ) {
                    type = OUR_SOURCE;
                }
            }
        }

        if (!endOfHeader && !type) {
            // Treat all the lines up to the first source line as header
            type = HEADER;
        }

        if (!type) {
            type = UNKNOWN;
        }

        // Strip out path names
        if ([SOURCE, OUR_SOURCE].includes(type)) {
            line = line.replace(basepath, basepathReplacement);
            parsed.filename = parsed.filename.replace(basepath, basepathReplacement);
        }

        return { line, parsed, type };
    });
}

// Formats an exception, line by line.
//
// * `lineFn({line, type})` should be a function which returns a string to use in place of the line.
//   `type` will be one of the type constants from the top of this file.
// * `options.maxLines` is the maximum number of lines to return.  0 or null for unlimited.
// * This function will call `String.replace(options.basepath, options.basepathReplacement)` on
//   every source line.  This can be used to strip the project folder from file pathnames.
//   `options.basepathReplacement` defaults to "./" if not specified.
//
const formatExceptionLines = function(exception, options, lineFn) {
    let lines = parseException(exception, options);
    const indent = (s) => {
        const indent = lines[lines.length -1].parsed && lines[lines.length -1].parsed.indent || '    ';
        return `${indent}${s}`;
    };

    if (isDefined(options.maxLines) && lines.length > options.maxLines) {
        lines = lines.slice(0, options.maxLines + 1);
        lines.push({ line: indent('[truncated]'), type: DIVIDER });
    }

    if (options.maxLines === 'auto') {
        let lastOwnedLine;
        for(let index = lines.length -1; index >= 0; index--) {
            if (lines[index].type === OUR_SOURCE) {
                lastOwnedLine = index;
                break;
            }
        }

        if (lastOwnedLine) {
            lines = lines.slice(0, lastOwnedLine + 1);
            lines.push({ line: indent('[truncated]'), type: DIVIDER });
        }
    }

    lines = lines.map(lineFn);

    return lines.join('\n');
};

const formatters = {
    // Format an exception as HTML.
    //
    // If `options.inlineStyle` is true, this will use inline styling for each line.
    // Otherwise each line will be given a CSS class ('hedaer', 'source', 'our-source', 'divider',
    // 'unknown').  Note that email generally will ignore CSS, so if you're emailing this exception,
    // inline stlying is a must.
    //
    html: function(exception, options = {}) {
        const html = formatExceptionLines(exception, options, function({ line, type }) {
            line = escapeHtml(line);

            const style = options.inlineStyle
                ? `style='${HTML_INLINE_STYLES[type] || ''}'`
                : `class=${type}`;

            // Use inline styles, since email doesn't support style sheets.
            switch (type) {
                case HEADER:
                    return `<h2 ${style}>${line}</h2>`;
                default:
                    return `<span ${style}>${line}</span><br />`;
            }
        });

        const style = options.inlineStyle ? "style='font-family: monospace'" : "class='exception'";
        return `<div ${style}>${html}</div>`;
    },

    ascii(exception, options = {}) {
        return formatExceptionLines(exception, options, function({ line, type }) {
            switch (type) {
                case OUR_SOURCE:
                    if (line[0] === ' ') {
                        return `*${line.slice(1)}`;
                    } else {
                        return line;
                    }
                default:
                    return line;
            }
        });
    },

    ansi: (function() {
        const colorizeLine = function(parsed) {
            const file = `${parsed.filename}:${parsed.line}:${parsed.column}`;
            if (isDefined(parsed.fn)) {
                return `${parsed.indent}at ${colors.magenta(parsed.fn)} (${colors.cyan(file)})`;
            } else {
                return `${parsed.indent}at (${colors.cyan(file)})`;
            }
        };
        return (exception, options = {}) =>
            formatExceptionLines(exception, options, function({ line, type, parsed }) {
                switch (type) {
                    case OUR_SOURCE:
                        if (isDefined(options.colors) ? options.colors : true) {
                            return colors.bold(colorizeLine(parsed));
                        } else {
                            return colors.bold(line);
                        }
                    // when SOURCE
                    //     colorizeLine(parsed)
                    default:
                        return line;
                }
            });
    })(),
};

//
// Parameters:
// * `options.format` - is one of "ansi", "ascii", "html".
// * This function will call `String.replace(options.basepath, options.basepathReplacement)` on
//   every source line.  This can be used to strip the project folder from file pathnames.
//   `options.basepathReplacement` defaults to "./" if not specified.
// * `options.maxLines` is the maximum number of stack trace lines to to print for an exception, 0
//   for unlimited.
//
module.exports = function(exception, options = {}) {
    const format = isDefined(options.format) ? options.format : 'ascii';
    return formatters[format](exception, options);
};

module.exports.parseExceptionLine = parseExceptionLine;
