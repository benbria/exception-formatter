fs       = require('fs');
longjohn = require('longjohn');
format   = require('../lib/exceptionFormatter')

function myFunction(done) {
    setImmediate(function() {
        return done(new Error("Arg!"));
    });
}

myFunction(function(err) {
    console.log(err.stack);
    console.log('');

    console.log(format(err));
    console.log('');

    console.log(format(err, {format: 'ansi'}));
    console.log('');

    fs.writeFileSync(__dirname + "/exception.html", format(err,{format: 'html', inlineStyle: true}));
});