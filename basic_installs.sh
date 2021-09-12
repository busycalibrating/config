#!/bin/bash

##### Basics
sudo apt update && sudo apt upgrade -y
sudo apt install -y vim git tmux gnome-tweaks

##### Install Signal
echo Installing Signal
# 1. Install official public software signing key
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null

# 2. Add repository to your list of repositories
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
  sudo tee -a /etc/apt/sources.list.d/signal-xenial.list

# 3. Update package database and install signal
sudo apt update && sudo apt install signal-desktop


##### Install Docker
echo Installing Docker...
# 1. Setup repository
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update && sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker engine
sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io

apt-cache madison docker-ce

echo Enter the version string to download
read version_string
echo Downloading: $version_string
sudo apt-get install docker-ce=$version_string docker-ce-cli=$version_string containerd.io

echo Testing docker engine...
sudo docker run hello-world

echo Creating docker group...
sudo groupadd docker
sudo usermod -aG docker $USER

echo Logout and login again to re-evaluate group membership
