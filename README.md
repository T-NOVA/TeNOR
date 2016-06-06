<img src="./ui/app/images/tenor_logo.png" height=150 />

This is TeNOR's, the [T-NOVA](http://www.t-nova.eu) Orchestrator repository.

## Prerequisites
- Gatekeeper (https://github.com/piyush82/auth-utils). Used for register TeNOR modules and save PoP information.
- Infrastructure Repository (https://github.com/T-NOVA/infrastructure-repository). Used by the UI and the Service Mapping algorithm.
- Service Mapping (https://github.com/T-NOVA/TeNOR/tree/master/service-mapper). Used when more than 1 PoP is available.
- Middleware API (optional). Required for start/stop VMs.
- VIM Monitoring (https://github.com/T-NOVA/vim-monitoring) (optional)

## Requirements
- Ruby >= 2.2
- Bundler
- MongoDB
- Apache Cassandra (optional, used for monitoring)
- Logstash (optional) & ElasticSearch (optional)
- Byobu (development) (sudo apt-get install byobu) (https://help.ubuntu.com/community/Byobu)
- RabbitMq

#Getting started

##Steps

1. Install and run the requirements (Gatekeeper and MongoDB). Installation scripts are provided in the `dependencies` folder.
2. Install TeNOR (internal dependencies and configurations)
3. Start TeNOR
4. Register the modules (each microservice)
5. Insert the Openstack information

## Installation
TeNOR has an installation script that helps with the installation and configuration of the Ruby Gem dependencies. Once is executed in a shell, the system asks a set of questions regarding the location of the MongoDB and the Gatekeeper. Then, automatically will install the Ruby Gem dependencies and will configure TeNOR.

Make sure that you have installed a Ruby version >= 2.2 and the `bundle` command is installed.

For the installation, run the following script:
`./tenor_installation.sh`

## Docker (alternative installation)

A Dockerfile is provided that provides a container with TeNOR and Gatekeeper installed.

## Execution

TeNOR can be executed in two ways:
1. Using Foreman
`foreman start`
2. Using Byobu (modern Tmux). Useful for developer purposes.
`./development.sh`

After execute the script you should use Byobu in order to see the running services.

##Registering modules in TeNOR/Gatekeeper
TeNOR is designed with a microservice architecture, this requires a registration of microservices to the system. The NS Manager is the responsible to manage this registration.

The registration of modules can be done with in two ways:

 - Using the TeNOR User Interface
 `Configuration -> Modules`
 - Using the following script:
 `./loadModules.sh`

The content of the loadModules.sh is a set of CuRL request to the NS Manager inserting the IP and PORT of each microservice. Automatically, the NS Manager register each module into Gatekeeper in order to generate a microservice-token.

##Loading PoP information in Gatekeeper

The PoP information is saved in Gatekeeper. This can be inserted in two manners:

 - Using the TeNOR User Interface:
 `Configuration -> PoPs`
 - Using the CLI:
 Get the Gatekeeper token:

```
tokenId=$(curl -XPOST http://$GATEKEEPER_IP:8000/token/ -H "X-Auth-Password:$GATEKEEPER_PASS" -H "X-Auth-Uid:$GATEKEEPER_USER_ID" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["token"]["id"]')
```

Post PoP Information:
```
 curl -X POST http://$GATEKEEPER_IP:8000/admin/dc/ \
   -H 'X-Auth-Token: '$tokenId'' \
   -d '{"msg": "PoP Testbed", "dcname":"default", "adminid":"keystoneUser","password":"keystonePass", "extrainfo":"pop-ip='$OPENSTACK_IP' tenant-name=tenantName keystone-endpoint=http://'$OPENSTACK_IP':35357/v2.0 orch-endpoint=http://'$OPENSTACK_IP':8004/v1 compute-endpoint=http://'$OPENSTACK_IP':8774/v2.1 neutron-endpoint=http://'$OPENSTACK_IP':9696/v2.0"}'
```

##User interface (UI)

TeNOR has a User Interface that provides a global view of the all the orchestration functionalities. Allows to read the descriptors, instantiatie a services, see the monitoring data and configure some parts.

This user interface is located in the `ui` folder and contains their own README file with the installation guide.

##Microservice ports
Each microservice is listening in different port. This port is configured in the `config.yml` file of each module (folder).

| Microservice | Port |
|--------|--------|
|    NS Manager    |    4000    |
|    NS Catalogue    |    4011    |
|    NSD Validator   |    4015    |
|    NS Provisioner    |    4012    |
|    NS Monitoring    |    4013    |
|    VNF Manager    |    4567    |
|    VNF Catalogue    |    4568    |
|    VNFD Validator    |    4570    |
|    VNF Catalogue    |    4572    |
|    VNF Monitoring    |    4573    |
|    HOT Generator    |    4571    |

##How test if TeNOR is installed and running

Make a request to the following address (NS Manager):

```
curl -XGET http://localhost:4000/
```

##License
Each module is published under different licenses, please take a look on each License file.