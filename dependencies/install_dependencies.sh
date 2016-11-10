#!/bin/bash
## Version: 0.1
## Author: Josep Batallé
## Organization: i2CAT

## Utilization:
## ./install_dependencies.sh  ->  Ask if wants to install each module.
## ./install_dependencies.sh  y n y  ->  Install some modules without ask. y => Yes, n => No
## $1 -> MongoDB
## $2 -> Ruby
## $3 -> RabbitMq
##

current_dir=$(pwd)

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

function echo_if {
  if [ $1 == 1 ]; then
    echo_pass $2
  else
    echo_fail $2
  fi
}

function install_rabbitmq {
    echo "Installing RabbitMq..."
#    wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.5/rabbitmq-server-generic-unix-3.6.5.tar.xz

    echo 'deb http://www.rabbitmq.com/debian/ testing main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list
    wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install rabbitmq-server

    echo "Restarting RabbitMq service"
    sudo service rabbitmq-server restart
}
function install_mongodb {
    echo "Installing mongodb..."
    dir="$(basename $current_dir)"
    if [ "$dir" = "dependencies" ]; then
        ./install_mongodb.sh
    elif [ "$dir" = "TeNOR" ]; then
        ./dependencies/install_mongodb.sh
    else
        echo "Script executed outside TeNOR folder. Install the UI manually or rerun the script."
        return
    fi
}

function install_ruby {
    echo "Installing RVM..."
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
	curl -sSL https://rvm.io/mpapis.asc | gpg --import -
    \curl -sSL https://get.rvm.io | bash -s stable
    echo "Installation of RVM done."

    cd ~
    . ~/.rvm/scripts/rvm

    echo "Installing Ruby 2.3.1..."
    rvm install 2.3.1
    echo "Installation of Ruby 2.3.1 done."

    echo "Installing Bundler..."
    gem install bundler invoker
    echo "Installation of Bundler done."
}

echo -e -n "\033[1;36mChecking if mongodb is installed"
mongod --version > /dev/null 2>&1
MONGO_IS_INSTALLED=$?
if [ $MONGO_IS_INSTALLED -eq 0 ]; then
    echo ">>> MongoDB already installed"
else
    if [ "$1" = "y" ]; then
        install=$1
    elif [ "$1" = "n"  ]; then
      echo "Skipping installation..."
    else
        echo "Do you want to install mongodb? (y/n)"
        read install
    fi
    if [ "$install" = "y" ]; then
      echo -e -n "\033[1;31mMongodb is not installed... Installing..."
      install_mongodb
    fi
fi

install="n"
echo -e -n "\033[1;36mChecking if ruby is installed"
. ~/.rvm/scripts/rvm > /dev/null 2>&1
ruby --version > /dev/null 2>&1
RUBY_IS_INSTALLED=$?
if [ $RUBY_IS_INSTALLED -eq 0 ]; then
    ruby_version=`ruby -e "print(RUBY_VERSION < '2.2.5' ? '1' : '0' )"`
    if [ $ruby_version -eq 1 ]; then
        echo -e "\nRuby version: " $RUBY_VERSION
        echo "Please, install a ruby version higher or equal to 2.2.5"
        echo -e -n "\033[1;31mRuby is not installed."
        if [ "$2" = "y" ]; then
            install=$2
        elif [ "$2" = "n"  ]; then
          echo "Skipping installation..."
        else
            echo -e "\nDo you want to install ruby? (y/n)"
            read install
        fi
        if [ "$install" = "y" ]; then
            install_ruby
            . ~/.rvm/scripts/rvm
        fi
    else
        echo ">>> Ruby is already installed"
    fi
else
    echo -e -n "\033[1;31mRuby is not installed."
    if [ "$2" = "y" ]; then
        install=$2
    elif [ "$2" = "n"  ]; then
      echo "Skipping installation..."
    else
        echo -e "\nDo you want to install ruby? (y/n)"
        read install
    fi
    if [ "$install" = "y" ]; then
        install_ruby
        . ~/.rvm/scripts/rvm
    fi
fi

install="n"
echo -e -n "\033[1;36mChecking if rabbitmq is installed"
rabbitmq-server --version > /dev/null 2>&1
RABBITMQ_IS_INSTALLED=$?
if [ $RABBITMQ_IS_INSTALLED -eq 0 ]; then
    echo ">>> RabbitMQ already installed"
else
    if [ "$3" = "y" ]; then
        install=$3
    elif [ "$3" = "n"  ]; then
      echo "Skipping installation..."
    else
        echo "Do you want to install rabbitmq for monitoring? (y/n)"
        read install
    fi

    if [ "$install" = "y" ]; then
      echo -e -n "\033[1;31mRabbitmq is not installed... Installing..."
      install_rabbitmq
    fi
fi

echo -e -n "\033[1;36mChecking if dependencies are installed\n"
echo "mongod          $(echo_if $(program_is_installed mongo))"
echo "ruby            $(echo_if $(program_is_installed ruby))"
echo "bundler         $(echo_if $(program_is_installed bundler))"
echo "rabbitmq             $(echo_if $(program_is_installed rabbitmq-server))"

. ~/.rvm/scripts/rvm
