<img src="./ui/app/images/tenor_logo.png" height=150 />

TeNOR is the NFV Orchestrator platform developed by the [T-NOVA](http://www.t-nova.eu) project, responsible for managing the entire NFV lifecycle service.

## Prerequisites
- Ruby >= 2.2.5 (installation provided in dependencies/install_dependencies.sh)
- Bundler (installation provided in dependencies/install_dependencies.sh)
- Gatekeeper (https://github.com/piyush82/auth-utils). (installation provided in dependencies/install_dependencies.sh)
- MongoDB (installation provided in dependencies/install_dependencies.sh)
- Openstack Juno version or higher

## Optional Requirements
- Service Mapping (https://github.com/T-NOVA/TeNOR/tree/master/service-mapper). Used when more than 1 PoP is available.
- Infrastructure Repository (https://github.com/T-NOVA/infrastructure-repository). Used by the UI and the Service Mapping algorithm.
- Middleware API (https://github.com/T-NOVA/mAPI) (required for start/stop the Lifecycle events inside the VNFS)
- VIM Monitoring (https://github.com/T-NOVA/vim-monitoring). Used for receive the monitoring from each VNF.
- Netfloc (https://github.com/T-NOVA/netfloc). Used for the VNFFG.
- WICM (https://github.com/T-NOVA/WICM).
- Apache Cassandra (optional, used for monitoring) (installation provided in dependencies/install_cassandra.sh)
- RabbitMq (optional, used for monitoring) (installation provided in dependencies/install_dependencies.sh)

#Getting started

## Steps
1. Install the prerequisites (Ruby, Gatekeeper and MongoDB). The installation of these requirements is provided a script inside the `dependencies` folder. Use the `install_dependencies.sh` script if you want to install it automatically.
2. Install TeNOR (internal dependencies and configurations). Installation script provided in the root folder `tenor_install.sh`.
3. Start TeNOR.
4. Register the internal modules (automatic) and external modules (Mapping, mAPI, WICM, VIMMonitoring, Netfloc...).
5. Register a Network Function Virtualisation Infrastructure Point of Presence (NFVI-PoP) inserting the Openstack credentials into Gatekeeper.
6. Test deploying a sample NSD/VNFD to the inserted NFVI-PoP.

## Installation
We provide an installation script for Ubuntu 14.04 that helps with the installation of Ruby, Gatekeeper and MongoDB.

In order to install Ruby, the MongoDB and Gatekeeper execute the following script:
```
./dependencies/install_dependencies.sh
```

For each requirement, the script will ask if you want to install it or not. Write `y` or `n` and press the Enter Key.

Once Ruby is installed (you can be sure of that using `ruby -v` command in the terminal), you can proceed with the TeNOR installation. In the root folder run the following script:
```
./tenor_install.sh
```

A menu will appear and you can choose a number in the menu [1-7].

For TeNOR installation, insert the number 1 and press the Enter Key. The installation will start automatically installing the Ruby Gem dependencies. After few minutes, the script will ask you a set of questions regarding the location of the MongoDB, Gatekeeper. In the case of insert an emty values, the script will use the default values (localhost).

**Make sure that you have installed a Ruby version >= 2.2.5 and the `bundle` command is installed.**

Once the installation finishes, TeNOR needs to be [started](#execution)

## Vagrant (alternative installation)

A Vagrantfile is provided with TeNOR, Gatekeeper and Mongodb installed.

## Docker (alternative installation)

A Dockerfile is provided that generates a container with TeNOR, Gatekeeper and Mongodb installed. Once is running, all the components are installed and running.

1. Build it with:

    ````
    docker build -t tnova/tenor .
    ````
2. Run the container with:

    ````
    docker run -itd -p 4000:4000 -p 8000:8000 -p 9000:9000 -v /opt/mongo:/var/lib/mongodb -v /opt/gatekeeper:/root/gatekeeper tnova/tenor bash
    ````
3. Then, you can test TeNOR ([Test if TeNOR is installed and running](#test-if-tenor-is-installed-and-running)), and you can access to the command line with:

    ````
    docker exec -i -t $DOCKER_ID /bin/bash
    ````

## Execution

TeNOR can be executed in two ways:

1. Using Invoker (http://invoker.codemancers.com) ([Help here](#using-invoker))

    ````
    invoker start invoker.ini
    ````
2. Using Byobu (modern Tmux). (sudo apt-get install byobu)  Useful for development purposes. ([Help here](#using-byobu))

    ````
    ./tenor_development.sh
    ````

How to test if TeNOR is installed [Test if TeNOR is installed and running](#test-if-tenor-is-installed-and-running)

### Using Invoker

Invoker is an utility to manage all the processes in the environment. The basic commands are the following:

 - invoker start invoker.ini -> Start TeNOR.
 - invoker reload ns-manager -> Restart the NS Manager service.
 - invoker list -> Show the list of running microservices and the status.

### Using Byobu

Byobu is a modern Tmux that allows to execute multiple shells in one terminal. Typing the command `byobu` you will see a list of windows created using the provided script. More information of Byobu in (https://help.ubuntu.com/community/Byobu).

Basic keys for using Byobu:

 - F3 and F4 for navigate through the windows
 - F6 exit from Byobu

## Registering modules in TeNOR and Gatekeeper
TeNOR has a microservice architecture and requires a registration of each microservices to the system. The NS Manager (API gateway) is the responsible to manage this registration. The internal TeNOR modules are managed automatically, but external modules like mAPI, WICM, Infrastructure repository and Netfloc needs to be registered.

The registration of modules can be done with in three ways:

 - Using [TeNOR User Interface](#user-interface)
 `Configuration -> Modules`
 - Using the TeNOR script:
 `./tenor_install.sh`
 - Using the following script:
 `./loadModules.sh`

The content of the loadModules.sh is a set of CuRL request to the NS Manager inserting the IP and PORT of each microservice. When the NS Manager recevies the requests, automatically register each module into Gatekeeper in order to generate a microservice-token.

## Loading NFVI-PoP information in Gatekeeper

The PoP information is saved in Gatekeeper. First of all, TeNOR recevies the registration requests and validates the authentication. If it works, TeNOR saves the PoP in Gatekeeper. The PoP can be inserted in two manners:

 - Using the TeNOR User Interface:
 `Configuration -> PoPs`
 - Using the TeNOR script:
  Execute the tenor_install.sh script and choose the option `4. Add new PoP`

## User Interface

TeNOR has a User Interface that provides a global view of the all the orchestration functionalities. Allows to read the descriptors, instantiate services, see the monitoring data and configure TeNOR.

This user interface is located in the `ui` folder and contains their own README file with the installation guide.

The UI uses Gatekeeper for authentication, so by default you need to use the default created user in Gatekeeper: t-nova-admin. Then, for the login:

- Username: t-nova-admin
- Password: Eq7K8h9gpg

#Initial steps

## Test if TeNOR is installed and running

Make a request to the following address (NS Manager):

```
curl -XGET http://localhost:4000/
```

If nothing is received, make sure that the NS Manager is running.
If you receive a response, means that the NS Manager is ready for recevie requests.

In order to see the available APIs for the NS Manager, visit the API Documentation (http://t-nova.github.io/TeNOR/)

## Define a VNFD and a NSD

Once TeNOR is ready to use, you should define a VNF Descriptor and a NS Descriptor. This task has some complexity and this repository contains a dummy descriptors that can be deployed without modification. You can find it in the NSD and VNFD validator modules.

The dummy NSD is located in:
` nsd-validator/assets/samples/nsd_example.json `

The dummy VNFD is located in:
` vnfd-validator/assets/samples/vnfd_example.json `

The next step is add the dummy descriptors to TeNOR system using the API. This step is explained in the following subsection.

### Upload a VNFD and NSD and instantiate it

In order to test TeNOR functionality, you can deploy a dummy NSD/VNFD located in the Validator folders. Follow the next steps in order to test TeNOR (you can copy and paste in the command prompt):

1. Add the VNFD in the VNF catalogue

    ````
    curl -XPOST localhost:4000/vnfs -H "Content-Type: application/json" --data-binary @vnfd-validator/assets/samples/vnfd_example.json
    ````
2. Add the NSD in the NS catalogue

    ````
    curl -XPOST localhost:4000/network-services -H "Content-Type: application/json" --data-binary @nsd-validator/assets/samples/nsd_example.json
    ````
3. Get the NSD ID (identification) from the NS Catalogue (getting the first NSD, so if more NSDs are defined, this command needs to be modified accordingly)

    ````
    ns_id=$(curl -XGET localhost:4000/network-services | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[0]["nsd"]["id"]')
    ````
4. Instantiate the NSD using the NSD ID extracted from the catalogue

    ````
    curl -XPOST localhost:4000/ns-instances -H "Content-Type: application/json" --data '{"ns_id": "'$ns_id'", "callbackUrl": "https://httpbin.org/post", "flavour": "basic"}'
    ````

### Other examples

We provide several examples with different functionalities. The VNFD_validator contains the VNFD examples and the NSD_validator folders the associtated NSDs.

The provided examples are:
- vnfd-validator/assets/samples/2911_vnfd_existing_image_id.json -> You can reuse an image already loaded in Openstack. Modify the IMAGE_ID field.
- vnfd-validator/assets/samples/2912_vnfd_existing_network_id.json -> You can reuse a network already created in Openstack. Modify the NETWORK_ID field.
- vnfd-validator/assets/samples/2913_vnfd_scaling.json -> You can see how scale out/in works with this example.

You can test it using the same commands shown before but chaning the file.

## Logs
TeNOR uses Fluentd in order to store the logs in a MongoDB. The UI inlcudes a view that allows to browser through the logs based on the date, severity and module.

## Write a Lifecycle events
In each VNFD can have 5 types of lifecycle event: start, stop, restart, scaling_out and scaling_in. For each type, some data can be requested, but basically, the different template is in the scaling actions.

 - Get PublicIp of port in a VDU: get_attr[vdu0,CP5v7d,PublicIp]
 - Get PrivateIp of port in a VDU: get_attr[CPr3k7,fixed_ips,0,ip_address]
 - Get the last VDU for scaling-out: get_attr[vdu1,vdus]
 - Get the last PrivateIps for scaling-out: gig-adaet_attr[CPsx4l,fixed_ips,0,ip_address]
 - Get the last PublicIps for scaling-out: get_attr[vdu0,CPudhr,PublicIp]
 - Timeout before remove instance due scale-in event:

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

# Bug reports and Feature requests

Please use [Github Issue Tracker](https://github.com/T-NOVA/TeNOR/issues) for feature requests or bug reports.

# License
Each module is published under different licenses, please take a look on each License file.
