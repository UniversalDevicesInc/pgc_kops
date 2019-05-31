#!/bin/bash

# ALB Controller Role
kubectl apply -f ./alb-ingress-role.yaml

# ALB Controller
kubectl apply -f ./alb-ingress-controller.yaml