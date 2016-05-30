#!/bin/bash

cd $HOME

echo "downloading and installing go runtime from google servers, please wait ..."
wget https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.4.2.linux-amd64.tar.gz

sudo -k

echo "configuring your environment for go projects ..."

export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

cd $HOME

echo "Downloading auth-utils code now, please wait ..."
mkdir $HOME/go
mkdir -p $HOME/go/src/github.com/piyush82
cd $HOME/go/src/github.com/piyush82
git clone https://github.com/piyush82/auth-utils.git
echo "done."

cd auth-utils
echo "getting all code dependencies for auth-utils now, be patient ~ 1-2 minutes"
go get
echo "done."

echo "compiling and installing the package"
go install
echo "done."

cd

echo "starting the auth-service next, you can start using it at port :8000"
echo "use Ctrl+c to stop it. The executable is located at: $GOPATH/bin/auth-utils"

#auth-utils