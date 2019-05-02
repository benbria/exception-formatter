import exceptionFormatter from '..';

const err = new Error();
const result = exceptionFormatter(err);

const ansi = exceptionFormatter(err, { format: 'ansi', colors: true });

const ascii = exceptionFormatter(err, { format: 'ascii', basepath: '/src/foo' });

const html = exceptionFormatter(err, { format: 'html', basepath: '/src/foo', inlineStyle: true });
