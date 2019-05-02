export = exceptionFormatter;

interface ExceptionFormatterOptionsCommon {
    maxLines?: number | null | 'auto';
    basepath?: string;
    basepathReplacement?: string;
}

type ExceptionFormatterOptions =
    | ExceptionFormatterOptionsCommon
    | ({ format: 'ascii' } & ExceptionFormatterOptionsCommon)
    | ({ format: 'ansi'; colors?: boolean } & ExceptionFormatterOptionsCommon)
    | ({ format: 'html'; inlineStyle?: boolean } & ExceptionFormatterOptionsCommon);

declare function exceptionFormatter(
    exception: Error | { stack: string } | string,
    options?: ExceptionFormatterOptions,
): string;
