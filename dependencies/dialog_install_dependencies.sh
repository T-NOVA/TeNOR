#!/bin/bash
# Author: Wojciech Mąka
#
#
#
installation () {
echo $1
    if [ $1 -eq 0 ] #install mongodb
    then
        echo -e -n "\033[1;36mChecking if mongodb is installed"
        mongod --version > /dev/null 2>&1
        MONGO_IS_INSTALLED=$?
        if [ $MONGO_IS_INSTALLED -eq 0 ]; then
            echo ">>> MongoDB already installed"
        else
            echo "Do you want to install mongodb? (y/n)"
            read install
            if [ "$install" = "y" ]; then
              echo -e -n "\033[1;31mMongodb is not installed... Installing..."
              install_mongodb
            fi
        fi

      prog=2
      return $prog
    fi
    if [ $1 -eq 1 ] #install gatekeeper
    then
        echo "Install gatekeeper"

      prog=4
      return $prog
    fi
    if [ $1 -eq 2 ] #install ruby
    then

      prog=6
      return $prog
    fi
    if [ $1 -eq 3 ] #install npm
    then

      prog=100
      return $prog
    fi
}

tmpv=${0%/*}
echo $tmpv
cd $tmpv

dialog --title "Installing prerequisites..." \
--backtitle "Installing prerequisites..." \
--msgbox "This installer will install all dependecies needed for buildig: couchdb-qt, " 10 40

cmd=(dialog --separate-output --checklist "Select options:" 22 76 16)
    options=(1 "Mongo DB" on    # any option can be set to default to "on"
             2 "Gatekeeper" on
             3 "Ruby" on
             4 "NodeJS / NPM" on
             5 "RabbitMQ" off)
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear

phase=0
prog=0
{
for choice in $choices
do
    echo $choice
    phase=$choice
     installation $phase
     prog=$?
     echo $prog
     phase=$[$phase+1]
done
} | dialog --title  "Installing prerequisites..." \
	   --backtitle "Installing prerequisites..." \
	   --gauge "Installation in progress... " 10 40 $prog