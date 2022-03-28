#!/bin/bash
set -x
date
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml
kubectl apply -f cluster-autoscaler-autodiscover.yaml

date
kubectl apply -f `echo $1 | cut -d "_" -f 2`.yaml

# kubectl apply -f taro.yaml
# kubectl apply -f nginx.yaml
# kubectl apply -f apache.yaml

# kubectl autoscale deployment taro-deployment --cpu-percent=50 --min=1 --max=6
# kubectl autoscale deployment nginx-deployment --cpu-percent=70 --min=1 --max=6
# kubectl autoscale deployment apache-deployment --cpu-percent=50 --min=1 --max=6
# kubectl delete horizontalpodautoscaler.autoscaling/apache-deployment

date
kubectl get pods --all-namespaces
kubectl get deployments
kubectl get svc
