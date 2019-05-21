#!/bin/bash
yum update -y
yum upgrade -y
yum install git -y
ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''
cd /home/ec2-user
su ec2-user -c "git clone https://github.com/UniversalDevicesInc/pgc_kops.git"
#amazon-linux-extras install -y
