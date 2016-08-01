// Karma configuration
// http://karma-runner.github.io/0.12/config/configuration-file.html
// Generated on 2015-05-22 using
// generator-karma 1.0.0

module.exports = function(config) {
  'use strict';

  config.set({
    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,

    // base path, that will be used to resolve files and exclude
    basePath: '../',

    // testing framework to use (jasmine/mocha/qunit/...)
    // as well as any additional frameworks (requirejs/chai/sinon/...)
    frameworks: [
      "jasmine"
    ],

    // list of files / patterns to load in the browser
    files: [
      // bower:js
      'bower_components/jquery/dist/jquery.js',
      'bower_components/angular/angular.js',
      'bower_components/angular-animate/angular-animate.js',
      'bower_components/angular-cookies/angular-cookies.js',
      'bower_components/angular-resource/angular-resource.js',
      'bower_components/angular-sanitize/angular-sanitize.js',
      'bower_components/angular-touch/angular-touch.js',
      'bower_components/angular-local-storage/dist/angular-local-storage.js',
      'bower_components/angular-bootstrap/ui-bootstrap-tpls.js',
      'bower_components/bootstrap/dist/js/bootstrap.js',
      'bower_components/angular-bootstrap-nav-tree/dist/abn_tree_directive.js',
      'bower_components/angular-smart-table/dist/smart-table.js',
      'bower_components/spin.js/spin.js',
      'bower_components/angular-loading/angular-loading.js',
      'bower_components/angular-strap/dist/angular-strap.js',
      'bower_components/angular-strap/dist/angular-strap.tpl.js',
      'bower_components/icheck/icheck.min.js',
      'bower_components/ui-router/release/angular-ui-router.js',
      'bower_components/x2js/xml2json.min.js',
      'bower_components/angular-x2js/dist/x2js.min.js',
      'bower_components/jquery-ui/jquery-ui.js',
      'bower_components/vis/dist/vis.min.js',
      'bower_components/eve/eve.js',
      'bower_components/raphael/raphael.min.js',
      'bower_components/mocha/mocha.js',
      'bower_components/morris.js/morris.js',
      'bower_components/underscore/underscore.js',
      'bower_components/d3/d3.js',
      'bower_components/angular-drag-and-drop-lists/angular-drag-and-drop-lists.js',
      'bower_components/checklist-model/checklist-model.js',
      'bower_components/angular-resizable/src/angular-resizable.js',
      'bower_components/tv4/tv4.js',
      'bower_components/angular-fullscreen/src/angular-fullscreen.js',
      'bower_components/angular-mocks/angular-mocks.js',
      // endbower
      "app/scripts/**/*.js",
      "test/mock/**/*.js",
      "test/spec/**/*.js"
    ],

    // list of files / patterns to exclude
    exclude: [
    ],

    // web server port
    port: 8080,

    // Start these browsers, currently available:
    // - Chrome
    // - ChromeCanary
    // - Firefox
    // - Opera
    // - Safari (only Mac)
    // - PhantomJS
    // - IE (only Windows)
    browsers: [
      "PhantomJS"
    ],

    // Which plugins to enable
    plugins: [
      "karma-phantomjs-launcher",
      "karma-jasmine"
    ],

    // Continuous Integration mode
    // if true, it capture browsers, run tests and exit
    singleRun: false,

    colors: true,

    // level of logging
    // possible values: LOG_DISABLE || LOG_ERROR || LOG_WARN || LOG_INFO || LOG_DEBUG
    logLevel: config.LOG_INFO,

    // Uncomment the following lines if you are using grunt's server to run the tests
    // proxies: {
    //   '/': 'http://localhost:9000/'
    // },
    // URL root prevent conflicts with the site root
    // urlRoot: '_karma_'
  });
};
