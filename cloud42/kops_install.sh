#!/bin/bash

# AWS Linux2 AMI
# EC2 role
# AmazonEC2FullAccess
# AmazonRoute53FullAccess
# AmazonS3FullAccess
# IAMFullAccess
# AmazonVPCFullAccess

sudo yum update -y
sudo yum upgrade -y
sudo yum install git -y


NAME=kube.aws.cloud42.dev
KOPS_STATE_STORE=s3://aws-cloud42-dev-state-store

# kubectl install
echo "Installing kubectl....."
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

# kops install
echo "Installing kops....."
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops

# Add environment to .bashrc
echo "Setting environment variables....."
export NAME=$NAME
export KOPS_STATE_STORE=$KOPS_STATE_STORE
echo "export NAME=$NAME" >> ~/.bashrc
echo "export KOPS_STATE_STORE=$KOPS_STATE_STORE" >> ~/.bashrc

# kops configure system
kops create cluster --master-count 1 --node-count 2 --zones us-east-1a,us-east-1b \
  --master-zones us-east-1a \
  -t private --networking weave \
  --node-size t2.micro \
  --master-size t2.micro $NAME

# modify cluster config if needed
# kops edit ig $NAME

# modify master config if necessary
# kops edit ig --name=$NAME master-us-east-1a

# modify nodes config if needed
# kops edit ig --name=kube.aws.cloud42.dev nodes

# deploy cluster on AWS
kops update cluster $NAME --yes
