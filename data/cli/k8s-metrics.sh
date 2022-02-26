#!/usr/bin/bash

# jq --raw-output '...| to_entries|map(.value)|@csv'
# | tee -a k8s-deploy-metrics.json
while true
do
dep_json=`kubectl get deployment -o json | jq -c '{ "time":now | strftime("%d-%m-%Y %H:%M:%S"),"readyReplicas": .items[0].status.readyReplicas, "replicas": .items[0].status.replicas, "name": .items[0].metadata.name}'`
hpa_json=`kubectl get hpa -o json | jq -c '.items[]|{ "time":now | strftime("%d-%m-%Y %H:%M:%S"),currentCPUUtilizationPercentage:.status.currentCPUUtilizationPercentage,currentReplicas:.status.currentReplicas,desiredReplicas:.status.desiredReplicas,targetCPU: .spec.targetCPUUtilizationPercentage}'`
echo $dep_json >> k8s-deploy-metrics.json
echo $hpa_json >> k8s-hpa-metrics.json
sleep 60;
done