#!/bin/bash

# get Token for dashboard login
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
# access dashboard
# ssh tunnel to kube manager instance, tunnel 8001:localhost:8001
# start proxy to cluster
echo "Browse to http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/"
kubectl proxy
