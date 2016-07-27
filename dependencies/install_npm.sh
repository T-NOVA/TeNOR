#!/bin/bash

echo "Installing NodeJS and NPM..."
sudo apt-get install nodejs-legacy npm
echo "Installation of NodeJS and NPM done."

echo "Installing Grunt and Bower..."
sudo npm install -g grunt grunt-cli bower
echo "Installation of Grunt and Bower done."

echo "Installing Compass..."
gem install compass
echo "Installation of Compass done."
