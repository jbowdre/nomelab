#!/bin/bash -eu

echo "==> Updating list of repositories"
apt-get clean
apt-get -y update

echo "==> Installing base package"
apt-get install -y git vim gpm

echo "==> Installing docker"
echo "installing dependencies"
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
echo "installing key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "sleep 1"
sleep 10
echo "installing repo"
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
echo "sleep 2"
sleep 10
echo "updating package cache"
apt-get update
echo "sleep 3"
sleep 10
echo "installing docker"
apt-get -y install docker-ce
echo "configuring group"
usermod -aG docker ${SSH_USERNAME}

echo "==> Adding docker to systemd"
mv /home/${SSH_USERNAME}/docker.service /lib/systemd/system/docker.service
chmod 644 /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker