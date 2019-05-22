#!/bin/bash

kubectl apply -f ./namespaces_and_serviceaccount.yaml

# Dashboard install
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml

# helm install
curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

# install helm
helm init --service-account tiller --history-max 200
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm repo update
aws logs create-log-group --log-group-name kubernetes.pgc-system \
  --region us-east-1 --retention-in-days 30
aws logs create-log-group --log-group-name kubernetes.nodeservers \
  --region us-east-1 --retention-in-days 30
aws logs create-log-group --log-group-name kubernetes.system \
  --region us-east-1 --retention-in-days 30
helm install --name fluentd incubator/fluentd-cloudwatch \
  -f ./fluentd.yaml --namespace logging
