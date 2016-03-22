'use strict';

module.exports = function (app) {
    var request = require('request');

    var http = require('http');

    /* your app config here */
    app.use('/rest/api', function (req, res) {

        var url;
        if (req.headers['x-host'] !== undefined) url = req.headers['x-host'] + req.url;
        else return;
        res.removeHeader('x-host');
        var r = null;

        if (req.method === 'POST') {
            if (!req.rawBody) {
                req.rawBody = "";
            }
            r = request.post({
                uri: url,
                body: req.rawBody,
                headers: {
                    'Content-Type': 'application/json'
                }
            }).pipe(res);

        } else if (req.method === 'PUT') {
            if (!req.rawBody) {
                req.rawBody = "";
            }
            r = request.put({
                uri: url,
                body: req.rawBody,
                headers: {
                    'Content-Type': 'application/json'
                }
            }).pipe(res);

        } else if (req.method === 'DELETE') {
            r = request.del({
                uri: url,
                body: ''
            }).pipe(res);

        } else {
            request({
                url: url,
                headers: {
                    'Accept': req.headers['accept']
                }

            }).pipe(res);
        }
    });
}
