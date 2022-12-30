---
slug: create-mongodb-docker
title: Create MongoDB Standalone and Replica Set containers using Docker
authors:
  name: Vishal Gandhi
  url: https://github.com/ivishalgandhi
  image_url: https://github.com/ivishalgandhi.png
tags: [mongodb,containers,docker,mongo-replicaset]
---

Docker Containers offer easy setup, customization and scalability. In this article, i will walk you through how to use Docker to setup MongoDB standalone and replica set containers within minutes.

The article is divided in two parts, the first part is setting up the standalone MongoDB container and second part is setting up and grouping MongoDB containers as member of replica set with Docker.

Let’s get started.

<!--truncate-->

## System Configuration

To run this setup, Docker Engine is required to be installed on the system. Follow the official documentation to setup Docker Engine on your system.

:::caution

The steps and configuration for both standalone and replica set is not to be used for production deployment. The intended use is only for setting up a environment to support learning of MongoDB.

:::

## Standalone MongoDB Setup

* Pull the Docker MongoDB official image from Docker Hub. The following code snippet demonstrates pulling the docker MongoDB 4.4.9 release. To pull the MongoDB 5.0 latest release replace :4.4.9-rc0 with :latest tag

```shell 

$ docker pull mongo:4.4.9-rc0 

```

* To check if the the image pull from Docker Hub was successful


```

$ docker images                                                   
REPOSITORY   TAG         IMAGE ID       CREATED       SIZE
mongo        4.4.9-rc0   24599d6cde30   9 days ago    413MB
mongo        latest      31299b956c79   10 days ago   642MB

```

* Lets start first standalone container – the below command starts MongoDB docker container with name mongo_449 in detached mode using the 4.4.9-rc0 image

```shell

$ docker run --name mongo_449 -d mongo:4.4.9-rc0

```

* List the container status and health by executing

```shell

$ docker container ls -a

CONTAINER ID   IMAGE          COMMAND                  CREATED       STATUS                      PORTS       NAMES
96e64ec525a2   24599d6cde30   "docker-entrypoint.s…"   2 hours ago   Up 33 minutes               27017/tcp   mongo_449

```

* To run a command inside the container
  * docker exec: interact with containers (running/up mode)
  * -i : interactive STDIN open even if not attached to the container
  * -t: pseudo TTY


* Connect to MongoDB daemon

```shell
root@96e64ec525a2:/# mongo

MongoDB shell version v4.4.9-rc0
connecting to: mongodb://127.0.0.1:27017/?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("ac624a79-908b-4580-90ae-22d0a7aee07a") }
MongoDB server version: 4.4.9-rc0

```

* Install utilities. The utilities ping, systemctl, sudo installed in the containers can be used for troubleshooting during the setup of Docker containers.

```shell

root@96e64ec525a2:/# apt-get install iputils-ping̵
root@96e64ec525a2:/# apt-get install sudo 
root@96e64ec525a2:/# apt-get install systemctl

```

This finishes the setup of standalone MongoDB Container. Now let’s look at ReplicaSet setup.

## Creating MongoDB ReplicaSet using Docker

A replica set consists of a primary node together with two or more secondary nodes. It is recommended to group three or more nodes, with an odd number of total nodes. The primary node accepts all the write requests which are propagated synchronously or asynchronously to the secondary nodes. Below are the steps required to complete the replica set setup using Docker.

Create a new network(bridge) within Docker. The replica set containers will be mapped to the new network.

```shell 
$ docker network create mongo_net
$ docker network inspect mongo_net                       
[
    {
        "Name": "mongo_net",
        "Id": "e2567806642a9245436371a9b9904c71fadae969fbd11a7bb8203e07976b1b2a",
        "Created": "2021-09-11T00:36:33.989688708Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
                }
            ]
        },
...
]
```

* Start 3 containers – Primary Secondary Secondary
  * Break down of parameters docker run : start a new container
    * `-d` :  run the container in detached mode
    * `-p 20001:27017` publish container port to the host and bind 27017 to 20001 on the host. This is useful if connecting mongo client like mongosh to container
    * `--name` : name of the mongo container
    * `-- network` : connect to user created network mongo_net
    * `mongo:4.4.9-rc0` : Docker MongoDB image
    * `mongod --replSet rs_mongo` : run the mongod daemon and add the container to replica set name rs_mongo

```shell 
$ docker run -d -p 20001:27017 --name mongo1 --network mongo_net mongo:4.4.9-rc0 mongod --replSet rs_mongo
$ docker run -d -p 20002:27017 --name mongo2 --network mongo_net mongo:4.4.9-rc0 mongod --replSet rs_mongo
$ docker run -d -p 20003:27017 --name mongo3 --network mongo_net mongo:4.4.9-rc0 mongod --replSet rs_mongo
```

* Set up Replica set. Connect to one of the containers and run the below commands. The container that receives the initiate will pass on the configuration to other containers assigned as members.

```js
rs_mongo [direct: primary] test_2> config = {
      "_id" : "rs_mongo",
      "members" : [
          {
              "_id" : 0,
              "host" : "mongo1:27017"
          },
          {
              "_id" : 1,
              "host" : "mongo2:27017"
          },
          {
              "_id" : 2,
              "host" : "mongo3:27017"
          }
      ]
  }

rs_mongo [direct: primary] admin> rs.initiate(config)

//Insert test data

rs_mongo [direct: primary] admin> use test_2
rs_mongo [direct: primary] test_2> db.employees.insert({name: "vishal")

//To read queries on secondary run setReadPref. 
rs_mongo [direct: secondary] test_2>db.getMongo().setReadPref('secondary')

rs_mongo [direct: secondary] test_2> db.employees.find()
[
  { _id: ObjectId("613c99801ea796508e3c73f5"), name: 'vishal' }
]

```

* Validate Replica Set Configuration

```js
rs_mongo [direct: primary] test_2> db.printReplicationInfo()

configured oplog size
'557174 MB'
---
log length start to end
'71372 secs (19.83 hrs)'
---
oplog first event time
'Sat Sep 11 2021 15:47:21 GMT+0530 (India Standard Time)'
---
oplog last event time
'Sun Sep 12 2021 11:36:53 GMT+0530 (India Standard Time)'
---
now
'Sun Sep 12 2021 11:36:54 GMT+0530 (India Standard Time)'


rs_mongo [direct: primary] test_2> rs.conf()
{
  _id: 'rs_mongo',
  version: 1,
  term: 1,
  protocolVersion: Long("1"),
  writeConcernMajorityJournalDefault: true,
  members: [
    {
      _id: 0,
      host: 'mongo1:27017',
      arbiterOnly: false,
      buildIndexes: true,
      hidden: false,
      priority: 1,
      tags: {},
      slaveDelay: Long("0"),
      votes: 1
    },
    {
      _id: 1,
      host: 'mongo2:27017',
      arbiterOnly: false,
      buildIndexes: true,
      hidden: false,
      priority: 1,
      tags: {},
      slaveDelay: Long("0"),
      votes: 1
    },
    {
      _id: 2,
      host: 'mongo3:27017',
      arbiterOnly: false,
      buildIndexes: true,
      hidden: false,
      priority: 1,
      tags: {},
      slaveDelay: Long("0"),
      votes: 1
    }

```
That concludes this article.












