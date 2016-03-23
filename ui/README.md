# TeNOR User interface
This is the TeNOR user interface. Can be used for monitoring the orchestrator status.

##Requirements
 - Node
 - Bower
 - Composer (Ruby gem)

##Installation steps
1. Install modules
Run `npm install` in the root folder. After that, change to api folder `cd api` and rerun the same command `npm install`.
After that, return to the root folder `cd ../`

2. Install javascript dependencies with Bower
Run `bower install`.

3. Install compass
Run `gem install compass`.

4. Configure the IPs
Copy the sample config file:
Run `cp app/config.js.sample app/config.js`
And edit the config.js with the correct IPs.

## Local Development
Run `grunt serve`.

##Production
Run `grunt serve:dist`.

##Testing
Running `grunt test` will run the unit tests with karma.

##Solving problems:
Sometimes, the grunt is not installed correctly, try running the folling command: `sudo npm install --global yo bower grunt-cli`
