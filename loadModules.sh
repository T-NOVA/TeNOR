#!/bin/bash

curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "gk",  "host": "localhost",  "port": 8000,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "ns_catalogue",  "host": "localhost",  "port": 4011,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "nsd_validator",  "host": "localhost",  "port": 4015,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "ns_provisioner",  "host": "localhost",  "port": 4012,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "ns_monitoring",  "host": "localhost",  "port": 4014,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "hot_generator",  "host": "localhost",  "port": 4571,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "ns_monitoring_repo",  "host": "localhost",  "port": 4017,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "vnf_manager",  "host": "localhost",  "port": 4567,  "path": ""}'

curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "mAPI",  "host": "localhost",  "port": 8080,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "WICM",  "host": "localhost",  "port": 1234,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "infr_repository",  "host": "localhost",  "port": 8888,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "mapping",  "host": "localhost",  "port": 4042,  "path": ""}'



