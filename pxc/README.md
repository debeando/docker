# My Percona XtraDB Cluster 5.7 Docker

## Build

```
docker build -t pxc:node .
```

## Create a network

```
docker network create --subnet=172.18.0.0/16 mynet
```

## Run

```
docker run --name=node01 \
           --detach \
           --tty \
           --rm \
           --ip 172.18.0.11 \
           --net mynet \
           --publish 0.0.0.0:3306:3306 \
           pxc:node
```

## Logs

```
docker logs -f node01
```

## Bash

```
docker exec -i -t node01 /bin/bash
```
