---
slug: percona-mongo-replicaset-minio
title: How to configure Percona MongoDB Replicaset, Percona Backup Manager, Backup Agent using Docker and perform Replicaset backup, restore using S3 compatible object storage – MINIO
authors:
  name: Vishal Gandhi
  url: https://github.com/ivishalgandhi
  image_url: https://github.com/ivishalgandhi.png
tags: [mongodb,containers,docker,s3,minio,pbm]
---


In this blog post, i will walk you through the steps required to containerize [Percona Server for MongoDB](https://github.com/percona/percona-server-mongodb), [Percona Backup Manager](https://github.com/percona/percona-backup-mongodb), and Agent from source and configure cloud-native S3(**S**imple **S**torage **S**ervice) compatible distributed object storage [MINIO](https://min.io/) to backup and restore Percona MongoDB snapshot backups.

<!--truncate-->

![](minio.webp)

## Prerequisites
Ensure the below binaries are installed before starting the setup and configuration

[Docker](https://www.docker.com/get-started/) or [Podman](https://podman.io/) to containerize Percona MongoDB replicaset and PBM Agent
[Docker Compose](https://docs.docker.com/compose/install/)
[Golang](https://go.dev/learn/) compiler – Build Percona Backup Manager binaries
[Portainer](https://www.portainer.io/) (Optional) – Intuitive UI for container configuration and monitoring
Let us perform the below steps to set up PSMDB Replicaset; PBM Agent; Minio, S3 compatible bucket, and PBM configuration to perform backups and restores from the bucket.

## Steps
* Create the Docker environment file with Docker Image, tag, port, and replicaset information. Save the file as .env in the working directory

```shell 
MONGODB_IMAGE=percona/percona-server-mongodb
MONGODB_VERSION=5.0
MONGO1_PORT=0.0.0.0:15000
MONGO2_PORT=0.0.0.0:15001
MONGO3_PORT=0.0.0.0:15002
MONGODB_PORT=27017
MONGODB_DOCKER_NETWORK=mongo_net
RS_NAME=rs1

```
* Create keyFile , Dockerfile and download percona-backup-manager source code in the working directory

```shell
$ git clone https://github.com/percona/percona-backup-mongodb.git

ARG MONGODB_VERSION
ARG MONGODB_IMAGE
FROM ${MONGODB_IMAGE}:${MONGODB_VERSION}
USER root
COPY keyFile /opt/keyFile
RUN chown mongodb /opt/keyFile && chmod 400 /opt/keyFile && mkdir -p /home/mongodb/ && chown mongodb /home/mongodb
USER mongodb
```
* Create Docker Compose file

```YAML
version: "3.8"
services:
  rs101:
    build:
      dockerfile: Dockerfile
      context: /home/vishal/dev/psmdb
      args:
        - MONGODB_VERSION=${MONGODB_VERSION}
        - MONGODB_IMAGE=${MONGODB_IMAGE}
    hostname: rs101
    labels:
      - "com.percona.pbm.app=mongod"
    environment:
      - REPLSET_NAME=rs1
      - MONGO_USER=dba
      - BACKUP_USER=bcp
      - MONGO_PASS=test1234
    ports:
      - "${MONGO1_PORT}:${MONGODB_PORT}"
    # command: mongod --replSet rs1 --port ${MONGO1_PORT}:27017 --storageEngine wiredTiger --keyFile /opt/keyFile --wiredTigerCacheSizeGB 1
    command: ["--replSet", "${RS_NAME}", "--bind_ip_all", "--storageEngine", "wiredTiger" , "--keyFile", "/opt/keyFile"]
    volumes:
      - data-rs101:/data/db
      - ./scripts/start.sh:/opt/start.sh
  rs102:
    build:
      dockerfile: Dockerfile
      context: /home/vishal/dev/psmdb
      args:
        - MONGODB_VERSION=${MONGODB_VERSION}
        - MONGODB_IMAGE=${MONGODB_IMAGE}
    hostname: rs102
    labels:
      - "com.percona.pbm.app=mongod"
    # command: mongod --replSet rs1 --port 27017 --storageEngine wiredTiger --keyFile /opt/keyFile --wiredTigerCacheSizeGB 1
    ports:
      - "${MONGO2_PORT}:${MONGODB_PORT}"
    command: ["--replSet", "${RS_NAME}", "--bind_ip_all", "--storageEngine", "wiredTiger" , "--keyFile", "/opt/keyFile"]
    volumes:
      - data-rs102:/data/db
  rs103:
    build:
      dockerfile: Dockerfile
      context: /home/vishal/dev/psmdb
      args:
        - MONGODB_VERSION=${MONGODB_VERSION}
        - MONGODB_IMAGE=${MONGODB_IMAGE}
    hostname: rs103
    labels:
      - "com.percona.pbm.app=mongod"
    # command: mongod --replSet rs1 --port 27017 --storageEngine wiredTiger --keyFile /opt/keyFile --wiredTigerCacheSizeGB 1
    ports:
      - "${MONGO3_PORT}:${MONGODB_PORT}"
    command: ["--replSet", "${RS_NAME}", "--bind_ip_all", "--storageEngine", "wiredTiger" , "--keyFile", "/opt/keyFile"]
    volumes:
      - data-rs103:/data/db
  agent-rs101:
    container_name: "pbmagent_rs101"
    user: "1001"
    labels:
      - "com.percona.pbm.app=agent"
      - "com.percona.pbm.agent.rs=rs1"
    environment:
      - "PBM_MONGODB_URI=mongodb://${BACKUP_USER:-bcp}:${MONGO_PASS:-test1234}@rs101:27017"
    build:
      labels:
        - "com.percona.pbm.app=agent"
      dockerfile: /home/vishal/open-source/percona-backup-mongodb/docker/Dockerfile
      context: /home/vishal/open-source/percona-backup-mongodb/
      args:
        - MONGODB_VERSION=${MONGODB_VERSION:-5.0}
    volumes:
      - ./conf:/etc/pbm
      - ./backups:/opt/backups
      - data-rs101:/data/db
    command: pbm-agent
    cap_add:
      - NET_ADMIN
  agent-rs102:
    container_name: "pbmagent_rs102"
    user: "1001"
    labels:
      - "com.percona.pbm.app=agent"
      - "com.percona.pbm.agent.rs=rs1"
    environment:
      - "PBM_MONGODB_URI=mongodb://${BACKUP_USER:-bcp}:${MONGO_PASS:-test1234}@rs102:27017"
    build:
      labels:
        - "com.percona.pbm.app=agent"
      dockerfile: /home/vishal/open-source/percona-backup-mongodb/docker/Dockerfile
      context: /home/vishal/open-source/percona-backup-mongodb/
      args:
        - MONGODB_VERSION=${MONGODB_VERSION:-5.0}
    volumes:
      - ./conf:/etc/pbm
      - ./backups:/opt/backups
      - data-rs102:/data/db
    command: pbm-agent
    cap_add:
      - NET_ADMIN
  agent-rs103:
    container_name: "pbmagent_rs103"
    user: "1001"
    labels:
      - "com.percona.pbm.app=agent"
      - "com.percona.pbm.agent.rs=rs1"
    environment:
      - "PBM_MONGODB_URI=mongodb://${BACKUP_USER:-bcp}:${MONGO_PASS:-test1234}@rs103:27017"
    build:
      labels:
        - "com.percona.pbm.app=agent"
      dockerfile: /home/vishal/open-source/percona-backup-mongodb/docker/Dockerfile
      context: /home/vishal/open-source/percona-backup-mongodb/
      args:
        - MONGODB_VERSION=${MONGODB_VERSION:-5.0}
    volumes:
      - ./conf:/etc/pbm
      - ./backups:/opt/backups
      - data-rs103:/data/db
    command: pbm-agent
    cap_add:
      - NET_ADMIN
volumes:
  backups: null
  data-rs101: null
  data-rs102: null
  data-rs103: null

```

* Run Docker compose
The below command will build and start the docker container for Percona Server MongoDB Primary Secondary Secondary replicaset and Percona Backup Manager Agent for each replicaset

```
$ psmdb docker compose -f docker-compose-rs.yaml up -d
[+] Running 8/8
⠿ Container psmdb-rs102-1 Running 0.0s
⠿ Container psmdb-rs103-1 Running 0.0s
⠿ Container pbmagent_rs103 Running 0.0s
⠿ Container pbmagent_rs102 Running 0.0s
⠿ Container psmdb-rs101-1 Running 0.0s
⠿ Container pbmagent_rs101 Running 0.0s

```

* Connect to MongoDB replicaset and ensure replication and containers are working

```shell
$ mongo "mongodb://dba:test1234@192.168.50.113:15000,192.168.50.113:15001,192.168.50.113:15002/admin?replicaSet=rs1"
```

* Setup Minio and Minio CLI

```shell

$ cd ~/downloads && wget https://dl.min.io/server/minio/release/linux-amd64/minio
 
$ wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
./mc --help
 
$  downloads ./minio server /home/vishal/data --address=0.0.0.0:7000
 

API: http://0.0.0.0:7000 
RootUser: minioadmin 
RootPass: minioadmin 
Finished loading IAM sub-system (took 0.0s of 0.0s to load data).
 
Console: http://192.168.50.113:43859 http://192.168.160.1:43859 http://172.18.0.1:43859 http://172.19.0.1:43859 http://172.24.0.1:43859 http://172.26.0.1:43859 http://172.17.0.1:43859 http://127.0.0.1:43859                   
RootUser: minioadmin 
RootPass: minioadmin 
 
Command-line: https://docs.min.io/docs/minio-client-quickstart-guide
   $ mc alias set myminio http://0.0.0.0:7000 minioadmin minioadmin
 
Documentation: https://docs.min.io


```

* Setup Minio server alias and List buckets

```shell
$  mc alias set minio-deb http://192.168.50.113:7000 minioadmin minioadmin
$  mc ls minio-deb
[2022-05-29 14:59:32 IST] 0B nocodb/
[2022-05-29 00:19:41 IST] 0B typesense/

```

* Create a new bucket and name it `pbm`

```shell
$ mc alias set minio-deb http://192.168.50.113:7000 minioadmin minioadmin
$ mc ls minio-deb
  [2022-05-29 14:59:32 IST] 0B nocodb/
  [2022-05-29 00:19:41 IST] 0B typesense/
```

* Setup PBM or compile PBM from the source repository

```shell
$ sudo apt-get install -y libkrb5-dev
$ cd percona-backup-mongodb
$ make build
$ make install
```
* create pbm_config.YAML to be used for configuring PBM for using MINIO

```YAML

storage:
    type: s3
    s3:
      endpointUrl: http://192.168.50.113:7000
      bucket: pbm
      credentials:
        access-key-id: "minioadmin"
        secret-access-key: "minioadmin"


```

* Configure PBM

```shell
$ ./pbm config --file /home/vishal/dev/psmdb/pbm_config.yaml --mongodb-uri="mongodb://bcp:test1234@192.168.50.113:15000/?replSetName=rs1"

```
* Validate agent container logs and run the pbm list command. If MINIO is configured successfully, agent container logs shouldn’t log any errors.

```shell
2022-05-29T01:31:14.000+0000 D [resync] got backups list: 02022-05-29T01:31:14.000+0000 D [resync] got physical restores list: 0

$ bin git:(main) ./pbm list --mongodb-uri="mongodb://bcp:test1234@192.168.50.113:15000/?replSetName=rs1"
Backup snapshots:
2022-05-29T01:29:12Z [complete: 2022-05-29T01:29:16Z]
2022-05-29T01:38:38Z [complete: 2022-05-29T01:38:42Z]
2022-05-29T04:04:44Z [complete: 2022-05-29T04:04:48Z]
```

* To run PBM backup and restore execute the below commands

```bash 
$ ./pbm backup --mongodb-uri="mongodb://bcp:test1234@192.168.50.113:15000/?replSetName=rs1" 
$ ./pbm restore 2022-05-29T04:04:44Z --mongodb-uri="mongodb:/
```