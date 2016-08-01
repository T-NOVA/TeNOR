#!/bin/bash

function program_is_installed {
  # set to 1 initially
  local return_=1
  # set to 0 if not found
  type $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  echo "$return_"
}

# display a message in red with a cross by it
# example
# echo echo_fail "No"
function echo_fail {
  # echo first argument in red
  printf "\e[31m✘ ${1}"
  # reset colours back to normal
  echo -e "\033[0m"
}

# display a message in green with a tick by it
# example
# echo echo_fail "Yes"
function echo_pass {
  # echo first argument in green
  printf "\e[32m✔ ${1}"
  # reset colours back to normal
  #echo "\033[0m"
  echo -e "\033[0m"
}

# echo pass or fail
# example
# echo echo_if 1 "Passed"
# echo echo_if 0 "Failed"
function echo_if {
  if [ $1 == 1 ]; then
    echo_pass $2
  else
    echo_fail $2
  fi
}

echo "Checking if mongodb is installed"
mongod --version > /dev/null 2>&1
MONGO_IS_INSTALLED=$?
if [ $MONGO_IS_INSTALLED -eq 0 ]; then
    echo ">>> MongoDB already installed"
    #service mongod restart
else
    echo "Mongodb is not installed... Installing..."
    ./install_mongodb.sh
    #bash -c "$(curl -fsSL https://raw.githubusercontent.com/steveneaston/Vaprobash/master/scripts/mongodb.sh)" bash $1 $2
fi

echo "Checking if gatekeeper is installed"
if [ -f ~/go/bin/auth-utils ]; then
  echo ">>> Gatekeeper already installed."
  if [ ! -f ~/gatekeeper.cfg ]; then
    cp go/src/github.com/piyush82/auth-utils/gatekeeper.cfg ~
  fi
else
    echo "Gatekeeper is not installed. Installing..."
    sudo apt-get install gcc -y
    ./install_gatekeeper.sh
fi

echo "Checking if ruby is installed"
. ~/.rvm/scripts/rvm
ruby --version > /dev/null 2>&1
RUBY_IS_INSTALLED=$?
if [ $RUBY_IS_INSTALLED -eq 0 ]; then
    ruby_version=`ruby -e "print(RUBY_VERSION < '2.2.0' ? '1' : '0' )"`
    if [ $ruby_version -eq 1 ]; then
        echo "Ruby version: " $RUBY_VERSION
        echo "Please, install a ruby version higher or equal to 2.2.0"
    else
        echo ">>> Ruby is already installed"
    fi
else
    echo "Ruby is not installed."
    ./install_ruby.sh
    . ~/.rvm/scripts/rvm
fi

npm --version > /dev/null 2>&1
NPM_IS_INSTALLED=$?
if [ $NPM_IS_INSTALLED -eq 0 ]; then
    echo ">>> NPM is already installed"
else
    echo "NPM is not installed."
    ./install_npm.sh
fi

echo "Checking if dependencies are installed"
echo "mongod          $(echo_if $(program_is_installed mongo))"
echo "ruby            $(echo_if $(program_is_installed ruby))"
echo "bundler         $(echo_if $(program_is_installed bundler))"
echo "node            $(echo_if $(program_is_installed node))"
echo "npm             $(echo_if $(program_is_installed npm))"
