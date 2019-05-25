#!/bin/bash

# AWS Linux2 AMI
# EC2 role
# AmazonEC2FullAccess
# AmazonRoute53FullAccess
# AmazonS3FullAccess
# IAMFullAccess
# AmazonVPCFullAccess

die () {
    echo >&2 "$@"
    exit 1
}
[ ! "$#" -eq 3 ] || die "Usage: ./kops_install.sh pgcdev.aws.cloud42.dev ./pgcdev.yaml, $# provided"
NAME=$1
DNAME=${NAME//./-}
KOPS_STATE_STORE=s3://${DNAME}-state-store
export NAME=$NAME
export KOPS_STATE_STORE=$KOPS_STATE_STORE

# AWS Create Buckets and Cloudwatch Logs Groups
aws s3api create-bucket --acl public-read --bucket ${DNAME}-ns-logs --region us-east-1
aws s3api create-bucket --acl public-read --bucket ${DNAME}-state-store --region us-east-1

aws logs create-log-group --log-group-name ${NAME}.pgc-system --region us-east-1
aws logs create-log-group --log-group-name ${NAME}.nodeservers --region us-east-1
aws logs create-log-group --log-group-name ${NAME}.system --region us-east-1
aws logs put-retention-policy --log-group-name ${NAME}.pgc-system \
  --retention-in-days 30 --region us-east-1
aws logs put-retention-policy --log-group-name ${NAME}.nodeservers \
  --retention-in-days 30 --region us-east-1
aws logs put-retention-policy --log-group-name ${NAME}.system \
  --retention-in-days 30 --region us-east-1

# kubectl install
echo "Installing kubectl....."
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# kops install
echo "Installing kops....."
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops

# Add environment to .bashrc
echo "Setting environment variables....."
echo "export NAME=$NAME" >> ~/.bashrc
echo "export KOPS_STATE_STORE=$KOPS_STATE_STORE" >> ~/.bashrc
source ~/.bashrc
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
source <(kops completion bash)
echo "source <(kops completion bash)" >> ~/.bashrc


# kops configure system ,us-east-1b \
kops create -f $2
#  -t private --networking weave \
# --node-size t2.large \
# --master-size t2.medium $NAME

# modify cluster config if needed
# kops edit ig $NAME

# modify master config if necessary
# kops edit ig --name=$NAME master-us-east-1a

# modify nodes config if needed
# kops edit ig --name=kube.aws.cloud42.dev nodes

# deploy cluster on AWS
# kops update cluster $NAME --yes
