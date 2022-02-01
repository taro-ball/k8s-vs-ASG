#!/bin/bash
set -x

# -a : save result
# -c 150: number of threads
# -n 10000000: total number of requests
# -qps -1: max queries per second
# -r 0.01: Resolution of the histogram lowest buckets in seconds

# k8s
kubectl get svc
# remember to enable metrics
myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep workers`
aws autoscaling enable-metrics-collection --auto-scaling-group-name $myasg --granularity "1Minute"
# scaling down before scaling
kubectl delete horizontalpodautoscaler.autoscaling/taro-deployment
kubectl apply -f taro.yaml
eksctl scale nodegroup --cluster=C888 --name=standard-workers --nodes=1
# re-create the autoscaler!

# ASG apache
# v2 alb=`aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[*].DNSName' --output text | grep asg`
lb=`aws elb describe-load-balancers --region us-east-1 --query 'LoadBalancerDescriptions[*].DNSName' --output text | sed 's/\s\+/\n/g' | grep asg`
echo $lb;cd;pwd; curl $lb:88/test.html
# ASG node
echo $lb;cd;pwd; curl $lb:3000

fortio load -a -c 50 -n 2000000 -qps -1 -r 0.01 -labels "hpa24 etc" http://$alb:88/test.html
fortio load -a -c 80 -t 600s -qps -1 -r 0.01 http://$lb:88/test.html
fortio load -a -c 80 -t 600s -qps -1 -r 0.01 http://$lb:3000
fortio load -a -c 80 -t 600s -qps -1 -r 0.01 -labels "after warmup scaleDown" http://$lb:3000
# quick check
egrep -rni QPS\|Threads\|Count *

# proper check
jq '{"URL": .Labels,StartTime,NumThreads,ActualQPS,\
"DurationSeconds": (.ActualDuration/1000000000),"TotalRequests": .DurationHistogram["Count"], \
"Percentiles":.DurationHistogram["Percentiles"][2]}' 2*


# jq '{"URL": .Labels,StartTime,NumThreads,ActualQPS,"DurationSeconds": (.ActualDuration/1000000000),"TotalRequests": .DurationHistogram["Count"],"Percentiles":.DurationHistogram["Percentiles"][2]}' 2*