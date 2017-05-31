# OSBS Box

A set of containers that emulate a OSBS deployment.

## Containers

### Koji Hub
https://docs.pagure.org/koji/server_howto/#koji-hub

Additional components:
* web interface
* koji-containerbuild plugin

Ports 80 and 443 are mapped to workstation.
Access console via https://localhost/koji

### Koji Builder
https://docs.pagure.org/koji/server_howto/#koji-daemon-builder

Additional components:
* koji-containerbuild plugin

### Koji DB
https://docs.pagure.org/koji/server_howto/#postgresql-server

### Openshift
https://docs.openshift.org/latest/getting_started/administrators.html#running-in-a-docker-container

Uses workstation's network.
Access console via https://localhost:8443
Username: osbs
Password: osbs

### Shared Data
A data volume container used to store shared data between
the containers:
* Certificates used by koji
* Koji client configuration files

### Client
Combination of client tools used to interact with other services
* osbs-client
* koji-cli
* koji-containerbuild-cli


## Getting Started

```
# Build all images
docker-compose build

# Start all containers in foreground
docker-compose up (Use -d for detached mode)

# Wait for client container to start

# Attach to client container
docker exec -it osbsbox_koji-client_1 bash

# Stop and remove all containers
docker-compose down
```

## Submitting Builds

```
# On client container
koji-containerbuild container-build candidate \
    git://my-git-registry.com/my-git-repo#4c16bf82213a94fb576cefe996fe70c5e384282f
```

## Using Koji CLI

```
# On client container
koji hello
```

## Koji Web Interface

Inspect koji-hub container logs to view link for accessing web interface:

```
docker-compose logs koji-hub
```

Example:
```
koji-hub_1      | + '[' '!' -e /docker-init ']'
koji-hub_1      | + mkdir -p /root/.koji
koji-hub_1      | + ln -fs /opt/koji-clients/kojiadmin/config /root/.koji/config
koji-hub_1      | + touch /docker-init
koji-hub_1      | ++ hostname -I
koji-hub_1      | + for ip in '`hostname -I`'
koji-hub_1      | + echo http://172.19.0.6/koji
koji-hub_1      | + echo http://172.19.0.6/kojifiles
koji-hub_1      | + exec httpd -D FOREGROUND
koji-hub_1      | [Thu Oct 06 15:18:37.651360 2016] [so:warn] [pid 1] AH01574: module ssl_module is already loaded, skipping

```
In this case, accessing http://172.19.0.6/koji from your browser shows koji's
web interface. http://172.19.0.6/kojifiles displays a directly listing of
/mnt/koji

## Common Questions/Known Issues

#### Unable to look up hostnames
OpenShift build may fail with an error like this:

`fatal: Unable to look up my-git-registry.com (port 9418) (Name or service not known)`

This seems to be due to docker not watching for iptables changes, to resolve:

```
sudo systemctl stop docker
sudo iptables -F
sudo iptables -t nat -F
sudo systemctl start docker
```

