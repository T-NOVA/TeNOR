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

2. Install javascript dependencies with Bower
Run `bower install`.

3. Configure the IPs
Copy the sample config file:
Run `cp app/config.js.sample app/config.js`
And edit the config.js with the correct IPs.

4. Execute the UI
Run `rake start` and the server will listen on port 9000 by default.