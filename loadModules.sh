#!/bin/bash

curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "ns_catalogue",  "host": "localhost",  "port": 4011,  "path": ""}' -H "X-Auth-Token: 504cec46-54e9-4ab1-8c72-aee9a72e5f36"
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "nsd_validator",  "host": "localhost",  "port": 4015,  "path": ""}'  -H "X-Auth-Token: 504cec46-54e9-4ab1-8c72-aee9a72e5f36"
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "ns_provisioning",  "host": "localhost",  "port": 4012,  "path": ""}' -H "X-Auth-Token: 504cec46-54e9-4ab1-8c72-aee9a72e5f36"
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "ns_monitoring",  "host": "localhost",  "port": 4014,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "hot_generator",  "host": "localhost",  "port": 4571,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "ns_monitoring_repository",  "host": "localhost",  "port": 4017,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "vnf_manager",  "host": "localhost",  "port": 4567,  "path": ""}'

curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "mAPI",  "host": "localhost",  "port": 8080,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "WICM",  "host": "localhost",  "port": 1234,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "infr_repo",  "host": "localhost",  "port": 8888,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "mapping",  "host": "localhost",  "port": 4042,  "path": ""}'

