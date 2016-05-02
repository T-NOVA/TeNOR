# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # Nombre logico de la imagen a partir de la que se crea la maquina virtaul.
  config.vm.box = "ubuntu/trusty64"

  config.memory = 2048
  config.cpus = 2

  config.vm.forward_port 4000, 4000
  config.vm.forward_port 8000, 8000

  # Lo siguiente, permite hacer el «provisionamiento» a Chef-solo
  # indicandole los cookbook que queremos que esten disponibles
  # en nuestro nueva maquina virtual

  config.vm.provision :chef_solo do |chef|
    ## Path relativo a este fichero
    chef.cookbooks_path = ["cookbooks", "site-cookbooks"]
    chef.add_recipe "apt"
    chef.add_recipe "build-essential"
    chef.add_recipe "nano"
    chef.add_recipe "vim"
    chef.add_recipe "ruby_build"
    chef.add_recipe "rbenv"
    chef.add_recipe "rbenv::user"
    chef.add_recipe "rbenv::vagrant"
    chef.add_recipe "mongodb"
    chef.add_recipe "nodejs"
    chef.add_recipe "nodejs::npm"

    chef.json = {
        rbenv: {
            user_installs: [{
                                user: 'vagrant',
                                rubies: ["2.2.1"],
                                global: "2.2.1",
                                gems: {
                                    "2.2.1" => [
                                        { name: "bundler" }
                                    ]
                                }
                            }]
        }
    }
  end

  #config.vm.share_folder "git","/home/vagrant/TeNOR","/home/yourhome/workspace/T-NOVA/TeNOR"
end
