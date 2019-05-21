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