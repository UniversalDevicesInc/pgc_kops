#!/bin/bash
yum update -y
yum upgrade -y
yum install git -y
cd /home/ec2-user
su ec2-user -c "ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''"
su ec2-user -c "git clone https://github.com/UniversalDevicesInc/pgc_kops.git"
#amazon-linux-extras install -y
