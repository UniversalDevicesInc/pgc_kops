#!/bin/bash

# AWS Linux2 AMI
# EC2 role
# AmazonEC2FullAccess
# AmazonRoute53FullAccess
# AmazonS3FullAccess
# IAMFullAccess
# AmazonVPCFullAccess
# CloudWatchLogsFullAccess

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -ne 2 ] && die "Usage: ./kops_install.sh pgc.prod.isy.io ./pgctest.yaml, $# provided"
NAME=$1
STATE_STORE=pgc-prod-state-store
DNAME=${NAME//./-}
export NAME=$NAME
export KOPS_STATE_STORE=s3://${STATE_STORE}
# Add environment to .bashrc
echo "Setting environment variables....."
echo "export NAME=$NAME" >> ~/.bashrc
echo "export KOPS_STATE_STORE=s3://${STATE_STORE}" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc


# AWS Create Buckets and Cloudwatch Logs Groups
aws s3api create-bucket --acl public-read --bucket ${DNAME}-ns-logs --region us-east-1
aws s3api create-bucket --acl public-read --bucket ${STATE_STORE} --region us-east-1

aws logs create-log-group --log-group-name ${NAME}.pgc-core --region us-east-1
aws logs create-log-group --log-group-name ${NAME}.nodeservers --region us-east-1
aws logs create-log-group --log-group-name ${NAME}.system --region us-east-1
aws logs put-retention-policy --log-group-name ${NAME}.pgc-core \
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

echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "source <(kops completion bash)" >> ~/.bashrc
source ~/.bashrc

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

# import ssh
kops create secret --name ${NAME} sshpublickey admin -i ~/.ssh/id_rsa.pub

# deploy cluster on AWS
kops update cluster $NAME --yes

echo "Log out and Back in before trying to manage the cluster."