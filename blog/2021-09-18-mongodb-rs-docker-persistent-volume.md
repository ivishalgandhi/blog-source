---
slug: mongodb-rs-docker-persistent-volume
title: MongoDB Replicaset with Persistent Volume using Docker Compose
authors:
  name: Vishal Gandhi
  url: https://github.com/ivishalgandhi
  image_url: https://github.com/ivishalgandhi.png
tags: [mongodb, docker,replicaset,persistent-volume]
---

In this article we will see the steps required to create and configure MongoDB replicaset containers on **persistent volumes** using [Docker Compose](https://docs.docker.com/compose/). Compose was developed to define, configure and spin-up multi-container docker applications with single command, further reducing . Extensive usage of Docker with several container management quickly becomes cumbersome, Compose overcomes this problem and allows to easily handle multiple containers at once using YAML configuration `docker-compose.yml`

<!--truncate-->

## Docker Compose Steps

### Step 1: System Configuration

To run Compose, make sure you have installed Compose on your local system where Docker is installed. The Compose setup and installation instructions can be found here.

### Step 2: Ensure mongo_net network bridge is already existing

```shell
$ docker network create mongo_net
$ docker network inspect mongo_net                       
```
### Step 3: Lets convert the below command as seen in previous blog post to docker-compose.yml. If you are new to Docker and drafting compose files try using composerize to convert docker run commands into compose YAML output

```shell 
$ docker run -d -p 20003:27017 --name mongo3 --network mongo_net mongo:4.4.9-rc0 mongod --replSet rs_mongo
```
There are few additional attributes passed in the `docker-compose.yml`. The difference in the options passed in the command line above and `docker-compose.yml` is as below

- image: custom image uploaded to docker hub with additional utilities installed on ubuntu build
hostname: container host name
- volumes: map directory on the host file system to manage and store container data. In the below YAML i use separate directory for all 3 MongoDB replicaset. This helps in creating persistent data store for docker containers and doesn’t bloat the container runtime instance.
- Pass mongod configuration options through file mongod.conf

Create the below YAML compose file in your favourite editor, i have been using Visual Studio Code. Save the file as docker-compose.yml


```shell
$ code .

``` 

```yaml
#version: "3.3"
services:
  mongo_1:
    image: ivishalgandhi/mongo-custom:latest
    hostname: mongo_1
    container_name: mongo_1
    volumes:
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_1/mongod.conf:/etc/mongod.conf
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_1/initdb.d/:/docker-entrypoint-initdb.d/
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_1/data/db/:/data/db/
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_1/log/:/var/log/mongodb/
    ports:
      - 20003:27017
    command: ["-f", "/etc/mongod.conf","--replSet", "rs_mongo"]
    network_mode: mongo_net
 
  mongo_2:
    image: ivishalgandhi/mongo-custom:latest
    hostname: mongo_2
    container_name: mongo_2
    volumes:
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_2/mongod.conf:/etc/mongod.conf
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_2/initdb.d/:/docker-entrypoint-initdb.d/
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_2/data/db/:/data/db/
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_2/log/:/var/log/mongodb/
    ports:
      - 20004:27017
    command: ["-f", "/etc/mongod.conf","--replSet", "rs_mongo"]
    network_mode: mongo_net
 
  mongo_3:
    image: ivishalgandhi/mongo-custom:latest
    hostname: mongo_3
    container_name: mongo_3
    volumes:
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_3/mongod.conf:/etc/mongod.conf
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_3/initdb.d/:/docker-entrypoint-initdb.d/
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_3/data/db/:/data/db/
      - /Users/vishalgandhi/learning/docker/mongo_replset/mongo_3/log/:/var/log/mongodb/
    ports:
      - 20005:27017
    command: ["-f", "/etc/mongod.conf","--replSet", "rs_mongo"]
    network_mode: mongo_net

```

### Step 4: create mongod.conf

```
$  code .

```

```YAML 
# mongod.conf
 
# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/
 
# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
 
# Where and how to store data.
storage:
  dbPath: /data/db
  journal:
    enabled: true
  engine:  wiredTiger
 
# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1  
```

### Step 5: Spin-up replicaset containers

```shell 
$ docker compose up -d
[+] Running 3/3
 ⠿ Container mongo_2  Created                                                                                                                                   0.2s
 ⠿ Container mongo_1  Created                                                                                                                                     0.2s
 ⠿ Container mongo_3  Created
```

### Step 6: Initiate replicaset

```shell
$ docker exec -it mongo_1 bash

root@mongo_1:/# mongo
rs_mongo:SECONDARY> rs.initiate(
   {
      _id: “rs_mongo”,
      version: 1,
      members: [
         { _id: 0, host : “mongo_1:27017” },
         { _id: 1, host : “mongo_2:27017” },
         { _id: 2, host : “mongo_3:27017” }
      ]
   }
)
 
rs_mongo:SECONDARY> db.isMaster() 
{
    "topologyVersion" : {
        "processId" : ObjectId("614615744d54c08963ef67f6"),
        "counter" : NumberLong(6)
    },
    "hosts" : [
        "mongo_1:27017",
        "mongo_2:27017",
        "mongo_3:27017"
    ],
    "setName" : "rs_mongo",
    "setVersion" : 1,
    "ismaster" : true,
    "secondary" : false,
    "primary" : "mongo_2:27017",
    "me" : "mongo_2:27017",

```