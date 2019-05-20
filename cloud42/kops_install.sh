# AWS Linux2 AMI
# EC2 role
# AmazonEC2FullAccess
# AmazonRoute53FullAccess
# AmazonS3FullAccess
# IAMFullAccess
# AmazonVPCFullAccess

# kubectl install
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# kops install
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops

# Add environment to .bashrc
echo .bashrc >> export NAME=kube.aws.cloud42.dev
echo .bashrc >> export KOPS_STATE_STORE=s3://aws-cloud42-dev-state-store

# Add environment to running session (or logout and back in)
export NAME=kube.aws.cloud42.dev
export KOPS_STATE_STORE=s3://aws-cloud42-dev-state-store

# kops configure system
kops create cluster --master-count 1 --node-count 2 --zones us-east-1a,us-east-1b --master-zones us-east-1a -t private --networking weave --node-size t2.micro --master-size t2.micro ${NAME}

# modify cluster config if needed
kops edit ig ${NAME}

# modify master config if necessary
kops edit ig --name=kube.aws.cloud42.dev master-us-east-1a

# modify nodes config if needed
kops edit ig --name=kube.aws.cloud42.dev nodes

# deploy cluster on AWS
kops update cluster ${NAME} --yes

# Dashboard install
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml

# apply dashboard-rbac-user.yml to api server
kubectl apply -f ../shared/dashboard-serviceaccount.yml

# helm install
curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

# install helm
helm init --service-account tiller --history-max 200
