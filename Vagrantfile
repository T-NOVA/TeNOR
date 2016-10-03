# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/trusty64"

	config.vm.provider :virtualbox do |vb|
		vb.customize ["modifyvm", :id, "--memory", "2048"] # is not required, but recommended
    vb.customize ["modifyvm", :id, "--cpus", "2"] # is not required, but recommended
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

	#config.vm.network :forwarded_port, guest: 4000, host: 4000 # tenor port
	config.vm.network :forwarded_port, guest: 8000, host: 8000 # gatekeeper port
	config.vm.network :forwarded_port, guest: 9000, host: 9000 # tenor UI port

  $script = <<-SCRIPT
    sudo apt-get update
    sudo apt-get install -y gcc git
    sudo apt-get remove --purge ruby-rvm ruby
    sudo rm -rf /usr/share/ruby-rvm /etc/rmvrc /etc/profile.d/rvm.sh
    rm -rf ~/.rvm* ~/.gem/ ~/.bundle*
    echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc
    echo "export rvm_max_time_flag=20" >> ~/.rvmrc

    echo "[[ -s '${HOME}/.rvm/scripts/rvm' ]] && source '${HOME}/.rvm/scripts/rvm'" >> ~/.bashrc
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -L https://get.rvm.io | bash -s stable --ruby

    source /home/vagrant/.rvm/scripts/rvm
    #rvm install 2.2.5
    gem install bundler
    gem install compass
    rvm group add rvm vagrant
    rvm fix-permissions
    cd ~
    git clone https://github.com/TeNOR/TeNOR.git
    cd TeNOR/
    ./dependencies/install_dependencies.sh y y n n

    #. ~/.rvm/scripts/rvm
    ./tenor_install.sh 1
    echo -e '#!/bin/bash \ncd /home/vagrant \ngo/bin/auth-utils &' > ~/gatekeeperd
    sudo mv ~/gatekeeperd /etc/init.d/gatekeeperd
    sudo chmod +x /etc/init.d/gatekeeperd
    sudo chown root:root /etc/init.d/gatekeeperd
    sudo update-rc.d gatekeeperd defaults
    sudo update-rc.d gatekeeperd enable
    #sudo service gatekeeperd start
  SCRIPT

  config.vm.provision "shell", inline: $script, privileged: false

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

end
