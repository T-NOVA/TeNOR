#!/bin/bash

curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "gk",  "host": "localhost",  "port": 8000,  "path": ""}'

curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "mAPI",  "host": "localhost",  "port": 8080,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "WICM",  "host": "localhost",  "port": 1234,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "infr_repository",  "host": "localhost",  "port": 8888,  "path": ""}'
curl -XPOST http://localhost:4000/configs/registerService -H "Content-Type: application/json" -d '{  "name": "mapping",  "host": "localhost",  "port": 4042,  "path": ""}'
