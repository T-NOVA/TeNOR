<img src="./tenor_logo.png" height=150 />

This is TeNOR's, the [T-NOVA](http://www.t-nova.eu) Orchestrator repository.

## Prerequisites
- Gatekeeper (https://github.com/piyush82/auth-utils). Used for register TeNOR modules and save PoP information.
- Infrastructure Repository (https://github.com/T-NOVA/infrastructure-repository). Used by the UI and the Service Mapping algorithm.
- Service Mapping (https://github.com/T-NOVA/TeNOR/tree/master/service-mapper). Used when more than 1 PoP is available.
- Middleware API (optional). Required for start/stop VMs.
- VIM Monnitoring (https://github.com/T-NOVA/vim-monitoring) (optional)

## Requirements
- Ruby >= 1.9
- Bundler
- MongoDB
- Apache Cassandra (optional, used for monitoring)
- Logstash (optional) & ElasticSearch (optional)
- Byobu (development) (sudo apt-get install byobu)

#Getting started
## Installation

Run the following script:
`./tenor_installation.sh`

## Execution

TeNOR can be executed in two ways:
1. Using Foreman
2. Using Byobu (modern Tmux). Useful for developer purposes.

Using Foreman:
`foreman start`

Using Byobu:
`./development.sh`

##Registering modules in Gatekeeper
The NS Manager needs to register the modules.

 - Using the TeNOR User Interface
 `Configuration -> Modules`
 -  Using the following script:
 `./loadModules.sh`

##Loading PoP information in Gatekeeper
It's possible to load the PoP information in two manners:

 - Using the TeNOR User Interface:
 - Using the CLI:

Get the Gatekeeper token:

```
tokenId=$(curl -XPOST http://$GATEKEEPER_IP:8000/token/ --header "X-Auth-Password:$GATEKEEPER_PASS" --header "X-Auth-Uid:$GATEKEEPER_USER_ID" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["token"]["id"]')
```

Post PoP Information:
```
 curl -X POST http://GATEKEEPER_IP:8000/admin/dc/  --header 'X-Auth-Token: '$tokenId'' \ -d '{"msg": "PoP Testbed", "dcname":"infrRepository-Pop-ID",\ "adminid":"kyestonUser","password":"keystonePass", "extrainfo":"pop-ip=OPENSTACK_IP keystone-endpoint=http://OPENSTACK_IP:35357/v2.0 orch-endpoint=http://OPENSTACK_IP:8004/v1"}
```

Each module is published under different licenses, please take a look on each License file.
