#!/bin/bash

echo "SO"
cat /etc/*-release

echo "Install Jenkins stable release"
yum remove -y java
yum install -y java-1.8.0-openjdk
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum install -y jenkins
chkconfig jenkins on

echo "Install git"
yum install -y git

echo "Install Docker engine"
yum update -y
yum install docker -y
usermod -aG docker ec2-user
service docker start

echo "Configure Jenkins"
chmod +x /tmp/install-plugins.sh
bash /tmp/install-plugins.sh
service jenkins start