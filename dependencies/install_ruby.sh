#!/bin/bash

echo "Installing RVM..."
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable
echo "Installation of RVM done."

cd ~
. ~/.rvm/scripts/rvm

echo "Installing Ruby 2.2.5..."
rvm install 2.2.5
echo "Installation of Ruby 2.2.5 done."

echo "Installing Bundler..."
gem install bundler
echo "Installation of Bundler done."
