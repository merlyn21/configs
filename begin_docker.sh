#!/bin/bash

apt-get update
apt-get install mc net-tools -y
#Install docker
apt-get remove docker docker-engine docker.io containerd runc
apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y

curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
