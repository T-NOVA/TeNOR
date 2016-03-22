<img src="./tenor_logo.png" height=150 />

This is TeNOR's, the [T-NOVA](http://www.t-nova.eu) Orchestrator repository.

## Requirements
- Ruby >= 1.9
- Bundler
- Gatekeeper (https://github.com/piyush82/auth-utils)
- MongoDB
- Infrastructure Repository (https://github.com/T-NOVA/infrastructure-repository)
- Service Mapping (https://github.com/T-NOVA/TeNOR/tree/master/service-mapper)
- Middleware API (optional)
- VIM Monnitoring (https://github.com/T-NOVA/vim-monitoring) (optional)
- Apache Cassandra
- Logstash (optional) & ElasticSearch (optional)
- Byobu (development) (sudo apt-get install byobu)

## Installation

Run the following script:
`./tenor_installation.sh`

## Executions

TeNOR can be executed in two ways:
1. Using Foreman
2. Using Byobu (modern Tmux). Useful for developer purposes.

Using Foreman:
`foreman start`

Using Byobu:
`./byobu.sh`

##Registering modules in Gatekeeper
 - Using the TeNOR User Interface
 Modules view 
 -  `./loadModules.sh`

##Loading PoPs in Gatekeeper
It's possible to load the PoP information in two manners:

 - Using the TeNOR User Interface:
 - Using the CLI:

Get the Gatekeeper token:
 `tokenId=$(curl -XPOST http://$GATEKEEPER_IP:8000/token/ --header "X-Auth-Password:Eq7K8h9gpg" --header "X-Auth-Uid:1" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["token"]["id"]') `

Post PoP Information:
 `curl -X POST http://GATEKEEPER_IP:8000/admin/dc/  --header 'X-Auth-Token: '$tokenId'' \ -d '{"msg": "PoP Testbed", "dcname":"infrRepository-Pop-ID",\ "adminid":"kyestonUser","password":"keystonePass", "extrainfo":"pop-ip=OPENSTACK_IP keystone-endpoint=http://OPENSTACK_IP:35357/v2.0 orch-endpoint=http://OPENSTACK_IP:8004/v1"}`

Each module is published under different licenses, please take a look on each License file.
