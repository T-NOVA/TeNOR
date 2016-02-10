#!/bin/bash

# Copyright 2014-2016 Universita' degli studi di Milano
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# -----------------------------------------------------
#
# Authors:
#     Alessandro Petrini (alessandro.petrini@unimi.it)
#
# -----------------------------------------------------


### TeNOR Service Mapper installer


NO_GLPK_CONTINUE=
OVERWRITE_CONTINUE=
BUNDLER_RET_VAL=
MAKE_RET_VAL=
MAKE_LOG_VAL=

echo
echo
echo
echo -e "\e[33m-----------------------------------------------------------"
echo -e "T-NOVA: TeNOR Service Mapper Installer (in living colours!)"
echo -e "-----------------------------------------------------------\e[39m"
echo
echo -e "This script will install the Service Mapper microservice and solver"
echo "wrapper into the folder:"
echo -e "  \e[32m$HOME/TeNOR-Mapper\e[39m"
echo
echo "The script will execute"
echo -e "\e[32m  apt-get update"
echo -e "\e[39mand then the following packages will be installed or updated via apt-get:"
echo -e "\e[32m  make, g++, Ruby, Bundler, zlib1g, zlib1g-dev"
echo
echo -e "\e[39mAlso, all the required Ruby gems dependencies will be resolved via Bundler"
echo
echo -e "Finally, the mapper requires a \e[32mGLPK-compatible solver\e[39m that must be present"
echo "on the target system."
echo "Check the readme for further instructions on how to download and install it."
echo
echo "(This script may require super user privileges to be run)"
echo -e "\e[94m(Press any key to continue)\e[39m"
read -n1 -s

#if [[ $EUID -ne 0 ]]; then
#    echo
#    echo -e "\e[91mThis script must be run as root!\e[39m"
#    exit 1
#fi

echo
echo -e "\e[94mChecking GLPK-compatible libraries\e[39m"
# Check if GLPK is present
GLPK_PRESENT=$(ldconfig -p | grep libglpk)
if [ "$GLPK_PRESENT" == "" ]
then
    echo
    echo
    echo -e "\e[91mGLPK library not found.\e[39m"
    echo
    echo "If regularly installed, try executing:"
    echo "  sudo ldconfig"
    echo "and restart this installer, otherwise check the readme for further"
    echo "instructions on how to download and install it."
    echo -e "Continue anyway? \e[94m(y/n)\e[39m"
    echo
    while :
    do
        read -s -n 1 NO_GLPK_CONTINUE
        if [[ "$NO_GLPK_CONTINUE" == 'n' || "$NO_GLPK_CONTINUE" == 'y' || "$NO_GLPK_CONTINUE" == 'N' || "$NO_GLPK_CONTINUE" == 'Y' ]]
        then
            break
        fi
    done

    if [[ "$NO_GLPK_CONTINUE" == 'n' || "$NO_GLPK_CONTINUE" == 'N' ]]
    then
        exit 1
    fi
else
    echo "Ok!"
fi

# Install/update required dependencies
echo
echo -e "\e[94mapt-get update\e[39m"
sudo apt-get update

echo
echo -e "\e[94minstalling or updating dependencies\e[39m"
sudo apt-get install -y make g++ ruby bundler zlib1g zlib1g-dev

# Check target directory
echo
echo -e "\e[94mChecking and creating target directory\e[39m"
if [ -d "$HOME/TeNOR-Mapper" ]
then
    echo
    echo -e "\e[33mDirectory \e[32m$HOME/TeNOR-Mapper \e[33malready exists!"
    echo -e "Some files may be overwritten: do you want to continue? \e[94m(y/n)\e[39m"
    while :
    do
        read -s -n 1 OVERWRITE_CONTINUE
        if [[ "$OVERWRITE_CONTINUE" == 'n' || "$OVERWRITE_CONTINUE" == 'y' || "$OVERWRITE_CONTINUE" == 'N' || "$OVERWRITE_CONTINUE" == 'Y' ]]
        then
            break
        fi
    done

    if [[ "$OVERWRITE_CONTINUE" == 'n' || "$OVERWRITE_CONTINUE" == 'N' ]]
    then
        exit 1
    fi
fi

# Create target directory
if [ ! -d "$HOME/TeNOR-Mapper" ]; then
    mkdir $HOME/TeNOR-Mapper
fi

#  Copy files
echo
echo -e "\e[94mCopying files\e[39m"
cp -r * $HOME/TeNOR-Mapper/.

# Silently remove install.sh from target directory
rm $HOME/TeNOR-Mapper/install.sh

# Update the Ruby Gems
echo
echo -e "\e[94mUpdating Ruby gems\e[39m"
cd $HOME/TeNOR-Mapper
sudo bundle update
#BUNDLER_RET_VAL=$(sudo bundle update)
#if [ "$BUNDLER_RET_VAL" -ne 0 ]
#then
#    echo "Bundler update failed. Check the onscreen log."
#    exit 5
#fi


# Compile the binary app
# jsonConverter is compiled anyhow
echo
echo -e "\e[94mClearing workspace and bin directories\e[39m"
cd $HOME/TeNOR-Mapper/bin
chmod "+x" clearworkspace.sh
./clearworkspace.sh
make clean
echo
echo -e "\e[94mCompiling jsonConverter application\e[39m"
make jsonConverter
MAKE_RET_VAL=$?
if [ "$MAKE_RET_VAL" -ne 0 ]
then
    echo -e "\e[33mFail during compilation!\e[39m"
    exit 1
fi

if [ "$GLPK_PRESENT" != "" ]
then
    echo
    echo -e "\e[94mCompiling solver application\e[39m"
    make solver
    MAKE_RET_VAL=$?
else
    echo
    echo
    echo -e "\e[33mSolving application has not been compiled since GLPK libraries are missing\e[39m"
    echo
    exit 1
fi

# Fixing ownership...
#echo -e "\e[94mChanging ownership to:\e[34m $USERNAME:$USERNAME\e[39m"
#chown -R $USER_ID:$USER_ID $HOME/TeNOR-Mapper

if [ "$MAKE_RET_VAL" -ne 0 ]
then
    echo -e "\e[33mFail during compilation!\e[39m"
    exit 1
fi

echo
echo
echo
echo -e "\e[92mInstallation was successful.\e[39m"
echo -e "Start the service by moving to \e[32m$HOME/TeNOR-Mapper\e[39m"
echo "and typing:"
echo -e "\e[32mrake start\e[39m"
echo
echo "By default, the service is listening to port 4042"
echo "and it can be changed by editing the config/config.yml file."
echo "Exit the service with Control-C"
echo
