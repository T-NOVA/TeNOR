# TeNOR User interface
This is the TeNOR user interface. Can be used for the management of the orchestrator, create descriptors, deploy services and monitor metrics.

##Requirements
 - Ruby
 - Bundler
 - Bower

##Installation steps
1. Install Ruby webserver and modules
First of all make sure that Ruby is installed in your system.

Then execute `bundle install` in order to install the ruby dependencies.

2. Configure the IPs
Copy the sample config file:
Run `cp app/config.js.sample app/config.js`
And edit the config.js with the correct IPs.

The UI uses the Gatekeeper Authentication. By default the UI has preconfigured the default user and password of Gatekeeper. If the admin password is different, please update the file app.rb.

3. Execute the UI
Run `rake start` and the server will listen on port 9000 by default.

4. Login to your system

Visit the page http://localhost:9000 in your browser.

Default user: admin
Default password: adminpass

##Development

A bower.json is provided, so you can include more javascript dependencies with Bower:

Run `bower install`.
