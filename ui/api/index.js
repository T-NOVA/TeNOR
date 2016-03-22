var express = require('express'),
    cors = require('cors'),
    fs = require('fs'),
    app = express(),
    bodyParser = require('body-parser');

app.use(cors());

function anyBodyParser(req, res, next) {
    var data = '';
    req.setEncoding('utf8');
    req.on('data', function (chunk) {
        data += chunk;
    });
    req.on('end', function () {
        req.rawBody = data;
        next();
    });
};

app.configure(function () {
    app.use(anyBodyParser);
});

require('./lib/proxy')(app);
require('./lib/gkProxy')(app);

module.exports = app;
