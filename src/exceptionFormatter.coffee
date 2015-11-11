# Module for pretty-formatting exceptions in HTML and Ascii.
#
# The functions in this module will parse JavaScript exceptions, identify which lines in the
# exception come from your application code (vs. exceptions from other modules in node_modules),
# and then format the exception to look pretty in HTML, or add ANSI color codes for display
# in a terminal.
#
# Example:
#
#     projectRoot = path.resolve(__dirname, "../..")
#
#     exceptionFormatter.formatHtml new Error("foo"), {
#         basepath: projectRoot
#     }
#

path   = require 'path'
colors = require 'colors/safe'

# Line Types
HEADER     = "header"
SOURCE     = "source"
OUR_SOURCE = "our-source"
UNKNOWN    = "unknown"
DIVIDER    = "divider"

# Borrowed from ejs
escapeHtml = (html) ->
    return String(html)\
        .replace(/&(?!\w+;)/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')

# Borrowed from lodash
isString = (value) ->
    typeof value is 'string' or
        value and typeof value is 'object' and toString.call(value) is '[object String]' or
        false

# Strip all ansi colors from a string.
stripColors = (str) ->
    re = new RegExp `'\033\[[0-9;]*m'`, 'g'
    return str.replace re, ''

endsWith = (str, suffix) -> str[-suffix.length..] is suffix

# Given a line from an exception, returns the {filename, line, column} of the exception, or
# null if the line cannot be parsed.
parseExceptionLine = do ->
    STACK_LINE_RE = /(\s*)at\s*([^\s]*)\s*\((.*?):(\d*):(\d*)\)/
    STACK_LINE_NO_FN_RE = /(\s*)at\s*(.*?):(\d*):(\d*)/

    return (line) ->
        match = STACK_LINE_RE.exec line
        if match
            return {indent: match[1], fn: match[2], filename: match[3], line: match[4], column: match[5]}
        else
            match = STACK_LINE_NO_FN_RE.exec line
            if match
                return {indent: match[1], filename: match[2], line: match[3], column: match[4]}
            else
                return null

# Parses an exception into lines.
# Returns a collection of {line, type} objects.
#
# This function will call `String.replace(options.basepath, options.basepathReplacement)` on
# every source line.  This can be used to strip the project folder from file pathnames.
# `options.basepathReplacement` defaults to "./" if not specified.
#
parseException = do ->
    DIVIDERS = [
        '    <<< async stack >>>' # streamline
        '    <<< raw stack >>>' # streamline
        '---------------------------------------------' # longjohn
    ]

    return (exception, options = {}) ->
        basepath = options.basepath ? process.cwd()

        # Add a trailing '/' to the basepath if it doesn't have one, because `__dirname` doesn't
        # have one.  Don't add the trailing '/' if it's a regex, because that's crazy talk.  :)
        if isString(basepath) and !endsWith(basepath, path.sep) then basepath += path.sep
        basepathReplacement = options.basepathReplacement ? ".#{path.sep}"

        exceptionText = if isString(exception)
            exception
        else if exception.stack?
            exception.stack
        else
            "" + exception

        value = stripColors exceptionText
        lines = value.split '\n'

        endOfHeader = false
        return lines.map (line) ->
            parsed = null

            # Figure out what kind of line each line is.
            if line in DIVIDERS
                endOfHeader = true
                type = DIVIDER

            else
                parsed = parseExceptionLine line
                if parsed
                    filename = parsed.filename
                    endOfHeader = true
                    type = SOURCE
                    if filename.indexOf('node_modules') is -1 and filename.search(basepath) isnt -1
                        type = OUR_SOURCE

            if !endOfHeader and !type
                # Treat all the lines up to the first source line as header
                type = HEADER

            if !type then type = UNKNOWN

            # Strip out path names
            if type in [SOURCE, OUR_SOURCE]
                line = line.replace basepath, basepathReplacement
                parsed.filename = parsed.filename.replace basepath, basepathReplacement

            {line, parsed, type}


# Formats an exception, line by line.
#
# * `lineFn({line, type})` should be a function which returns a string to use in place of the line.
#   `type` will be one of the type constants from the top of this file.
# * `options.maxLines` is the maximum number of lines to return.  0 or null for unlimited.
# * This function will call `String.replace(options.basepath, options.basepathReplacement)` on
#   every source line.  This can be used to strip the project folder from file pathnames.
#   `options.basepathReplacement` defaults to "./" if not specified.
#
formatExceptionLines = (exception, options, lineFn) ->
    lines = parseException exception, options

    if options.maxLines and lines.length > options.maxLines
        lines = lines[0..options.maxLines]
        lines.push lineFn("[truncated]", DIVIDER)

    lines = lines.map lineFn

    return lines.join '\n'

formatters = {
    # Format an exception as HTML.
    #
    # If `options.inlineStyle` is true, this will use inline styling for each line.
    # Otherwise each line will be given a CSS class ('hedaer', 'source', 'our-source', 'divider',
    # 'unknown').  Note that email generally will ignore CSS, so if you're emailing this exception,
    # inline stlying is a must.
    #
    html: do ->
        INLINE_STYLES = {}
        INLINE_STYLES[OUR_SOURCE] = "white-space:nowrap; font-weight:bold; color: #800"
        INLINE_STYLES[SOURCE]     = "white-space:nowrap; color: #888"
        INLINE_STYLES[DIVIDER]    = "white-space:nowrap; color: #000"

        return (exception, options={}) ->
            html = formatExceptionLines exception, options, ({line, type}) ->
                line = escapeHtml line

                style = if options.inlineStyle
                    "style='#{INLINE_STYLES[type] ? ''}'"
                else
                    "class=#{type}"

                # Use inline styles, since email doesn't support style sheets.
                switch type
                    when HEADER     then "<h2 #{style}>#{line}</h2>"
                    else "<span #{style}>#{line}</span><br />"

            style = if options.inlineStyle then "style='font-family: monospace'" else "class='exception'"
            return "<div #{style}>#{html}</div>"

    ascii: (exception, options={}) ->
        return formatExceptionLines exception, options, ({line, type}) ->
            switch type
                when OUR_SOURCE
                    if line[0] == ' ' then ("*" + line.slice(1)) else line
                else line

    ansi: do ->
        colorizeLine = (parsed) ->
            file = "#{parsed.filename}:#{parsed.line}:#{parsed.column}"
            if parsed.fn?
                return "#{parsed.indent}at #{colors.magenta(parsed.fn)} (#{colors.cyan(file)})"
            else
                return "#{parsed.indent}at (#{colors.cyan(file)})"
        return (exception, options={}) ->
            return formatExceptionLines exception, options, ({line, type, parsed}) ->
                switch type
                    when OUR_SOURCE
                        if options.colors ? true
                            colors.bold(colorizeLine(parsed))
                        else
                            colors.bold(line)
                    # when SOURCE
                    #     colorizeLine(parsed)
                    else line
}

#
# Parameters:
# * `options.format` - is one of "ansi", "ascii", "html".
# * This function will call `String.replace(options.basepath, options.basepathReplacement)` on
#   every source line.  This can be used to strip the project folder from file pathnames.
#   `options.basepathReplacement` defaults to "./" if not specified.
# * `options.maxLines` is the maximum number of stack trace lines to to print for an exception, 0
#   for unlimited.
#
module.exports = (exception, options={}) ->
    format = options.format ? 'ascii'
    return formatters[format] exception, options

module.exports.parseExceptionLine = parseExceptionLine