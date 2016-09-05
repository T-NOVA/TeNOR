<img src="./ui/app/images/tenor_logo.png" height=150 />

TeNOR is the NFV Orchestrator platform developed by the [T-NOVA](http://www.t-nova.eu) project, responsible for managing the entire NFV lifecycle service.

## Prerequisites
- Gatekeeper (https://github.com/piyush82/auth-utils). Used for register TeNOR modules and save PoP information.
- Infrastructure Repository (https://github.com/T-NOVA/infrastructure-repository). Used by the UI and the Service Mapping algorithm.
- Service Mapping (https://github.com/T-NOVA/TeNOR/tree/master/service-mapper). Used when more than 1 PoP is available.
- Middleware API (https://github.com/T-NOVA/mAPI) (optional but required for start/stop the Lifecycle events inside the VNFS)
- VIM Monitoring (https://github.com/T-NOVA/vim-monitoring) (optional)

## Requirements
- Ruby >= 2.2.5
- Bundler
- MongoDB
- Apache Cassandra (optional, used for monitoring)
- Logstash (optional) & ElasticSearch (optional)
- Byobu (development) (sudo apt-get install byobu) (https://help.ubuntu.com/community/Byobu)
- RabbitMq (optional, used for monitoring)
- Openstack with Neutron ML2 Port Security plugin. Requires a change in /etc/nova/nova.conf with the following field: `security_group_api = nova`

#Getting started

## Steps

1. Install and run the requirements (Gatekeeper and MongoDB). Installation scripts are provided in the `dependencies` folder. Use the `install_dependencies.sh` script if you want to install all the dependencies.
2. Install TeNOR (internal dependencies and configurations)
3. Start TeNOR
4. Register the internal modules (each microservice) and external modules (Mapping, mAPI, WICM, VIMMonitoring, Netfloc...)
5. Register a Point of Presence (PoP) inserting the Openstack credentials into Gatekeeper

## Installation
We provide an installation script that helps with the installation of the Ruby Gem dependecies, the configuration of the system and the registration of the modules and PoPs.

Run the following script:
`./tenor_install.sh`

and choose a number in the menu [1-5].

For TeNOR installation, insert the number 1, press the Enter key and the installation will start. The script will asks a set of questions regarding the location of the MongoDB, Gatekeeper and Logstash. Then, automatically will install the Ruby Gem dependencies and will configure TeNOR. **Make sure that you have installed a Ruby version >= 2.2 and the `bundle` command is installed.**

Once the installation finishes, TeNOR needs to be [started](#execution)

## Docker (alternative installation)

A Dockerfile is provided that generates a container with TeNOR and Gatekeeper and a mongodb installed.

## Vagrant (alternative installation)

A Vagrantfile is provided with TeNOR, Gatekeeper and a mongodb installed.

## Execution

TeNOR can be executed in two ways:

1. Using Byobu (modern Tmux). Useful for development purposes.
   `./tenor_development.sh`
2. Using Foreman
   `foreman start`

In the case of using Byobu, you'll see three sessions, one for the NS manager, one for the VNF manager and one for the UI. Inside each session use use F3 and F4 keys for navigate through the windows.

How to test if TeNOR is installed [Test if TeNOR is installed and running](#test-if-tenor-is-installed-and-running)

## Registering modules in TeNOR and Gatekeeper
TeNOR has a microservice architecture and requires a registration of each microservices to the system. The NS Manager (API gateway) is the responsible to manage this registration. The interal TeNOR modules are managed automatically, but external modules like Gatekeeper, mAPI, WICM needs to be registered.

The registration of modules can be done with in two ways:

 - Using [TeNOR User Interface](#user-interface)
 `Configuration -> Modules`
 - Using the following script:
 `./loadModules.sh`

The content of the loadModules.sh is a set of CuRL request to the NS Manager inserting the IP and PORT of each microservice. When the NS Manager recevies the requests, automatically register each module into Gatekeeper in order to generate a microservice-token.

Make sure to pu

## Loading PoP information in Gatekeeper

The PoP information is saved in Gatekeeper. This can be inserted in three manners:

 - Using the TeNOR User Interface:
 `Configuration -> PoPs`
 - Using the TeNOR script:
  Execute the tenor_install.sh script and choose the option` **4. Add new PoP**
 - Using the CLI:

 First of all, define the following variables:

```
 GATEKEEPER_IP=localhost
 GATEKEEPER_PASS=Eq7K8h9gpg
 GATEKEEPER_USER_ID=1
 OPENSTACK_IP=localhost
 admin_tenant_name=tenantName
 keystonePass=password
 keystoneUser=admin
```

 Get the Gatekeeper token (you can copy and paste in the command prompt):

```
tokenId=$(curl -XPOST http://$GATEKEEPER_IP:8000/token/ -H "X-Auth-Password:$GATEKEEPER_PASS" -H "X-Auth-Uid:$GATEKEEPER_USER_ID" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["token"]["id"]')
```

Post PoP Information (you can copy and paste in the command prompt):
```
 curl -X POST http://$GATEKEEPER_IP:8000/admin/dc/ \
   -H 'X-Auth-Token: '$tokenId'' \
   -d '{"msg": "PoP Testbed", "dcname":"default", "adminid":"'$keystoneUser'","password":"'$keystonePass'", "extrainfo":"pop-ip='$OPENSTACK_IP' tenant-name='$admin_tenant_name' keystone-endpoint=http://'$OPENSTACK_IP':35357/v2.0 orch-endpoint=http://'$OPENSTACK_IP':8004/v1 compute-endpoint=http://'$OPENSTACK_IP':8774/v2.1 neutron-endpoint=http://'$OPENSTACK_IP':9696/v2.0"}'
```

## User Interface

TeNOR has a User Interface that provides a global view of the all the orchestration functionalities. Allows to read the descriptors, instantiatie a services, see the monitoring data and configure some parts.

This user interface is located in the `ui` folder and contains their own README file with the installation guide.

#Initial steps

## Test if TeNOR is installed and running

Make a request to the following address (NS Manager):

```
curl -XGET http://localhost:4000/
```

If nothing is received, make sure that all the modules are running.

## Define a VNFD and a NSD

The next step is start creating descriptors. Anyway, this repository contains a dummy descriptors that can be deployed without modification. You can find it in the NSD and VNFD validator modules.

The dummy NSD is located in:
` nsd-validator/assets/samples/nsd_example.json `

The dummy VNFD is located in:
` vnfd-validator/assets/samples/vnfd_example.json `

The next step is add the dummy descriptors to TeNOR system using the API. This step is expained in the following subsection.

## Create a VNFD and NSD and instantiate it

In order to test TeNOR functionallity, you can follow the next steps (you can copy and paste in the command prompt):

1. Add the VNFD in the catalogue
` curl -XPOST localhost:4000/vnfs -H "Content-Type: application/json" --data-binary @vnfd-validator/assets/samples/vnfd_example.json `
2. Add the NSD in the catalogue
` curl -XPOST localhost:4000/network-services -H "Content-Type: application/json" --data-binary @nsd-validator/assets/samples/nsd_example.json `
3. Get the NSD from the NS Catalogue (getting the first NSD)
` ns_id=$(curl -XGET localhost:4000/network-services | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[0]["nsd"]["id"]') `
4. Instantiate the NSD using the NSD ID extracted from the catalogue
` curl -XPOST localhost:4000/ns-instances -H "Content-Type: application/json" --data '{"ns_id": "'$ns_id'", "callbackUrl": "https://httpbin.org/post", "flavour": "basic"}' `

# Development

## Microservice ports
Each microservice is listening in different port. This port is configured in the `config.yml` file of each module (folder).

| Microservice | Port |
|--------|--------|
|    NS Manager    |    4000    |
|    NS Catalogue    |    4011    |
|    NS Provisioner    |    4012    |
|    NS Monitoring    |    4013    |
|    NSD Validator   |    4015    |
|    VNF Manager    |    4567    |
|    VNF Catalogue    |    4568    |
|    VNFD Validator    |    4570    |
|    HOT Generator    |    4571    |
|    VNF Catalogue    |    4572    |
|    VNF Monitoring    |    4573    |


# License
Each module is published under different licenses, please take a look on each License file.