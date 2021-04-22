#!/bin/bash

# install docker
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo apt-get install pass gnupg2 -y
sudo curl -L https://github.com/docker/compose/releases/download/1.27.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
getent group docker || sudo groupadd docker
sudo usermod -aG docker ${user}

# python (pip3)
sudo apt-get install python3-pip -y

# AWS CLI
rm -rf "/home/${user}/aws"
sudo apt-get install unzip -y
AWSCLI_PATH="/home/${user}/awscliv2.zip"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o $AWSCLI_PATH
(cd "/home/${user}" && unzip awscliv2.zip && sudo ./aws/install)

# Mysql client
sudo apt install mysql-client-core-5.7 -y

hostname "${name}"
sed -i "s/[^ ]*/${name}/g" /etc/hostname