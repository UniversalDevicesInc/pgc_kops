#!/bin/bash

# Echoserver
kubectl apply -f ./echoserver-deployment.yaml

# Ingress for Echoserver
kubectl apply -f ./echoserver-ingress.yaml