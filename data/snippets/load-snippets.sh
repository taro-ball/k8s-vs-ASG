#!/bin/bash
set -x

# -a : save result
# -c 150: number of threads
# -n 10000000: total number of requests
# -qps -1: max queries per second
# -r 0.01: Resolution of the histogram lowest buckets in seconds

# 
chmod +x load.sh
screen
# ctrl+a > ctrl + d
./load.sh | tee -a log.txt 

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
fortio load -a -c 15 -t 45s -qps -1 -r 0.01 -labels "warmup" http://$lb:3000

 for((i=10;i<=20;i+=1)); do fortio load -a -c 15 -t 60s -qps -1 -r 0.01 -labels "warmup" http://$lb:3000?n=9999; done
-allow-initial-errors
# quick check
egrep -rni QPS\|Threads\|Count *

# proper check
jq '{"URL": .Labels,StartTime,NumThreads,ActualQPS,\
"DurationSeconds": (.ActualDuration/1000000000),"TotalRequests": .DurationHistogram["Count"], \
"Percentiles":.DurationHistogram["Percentiles"][2]}' 2*


# jq '{"Labels": .Labels,URL,StartTime,NumThreads,ActualQPS,"DurationSeconds": (.ActualDuration/1000000000),"TotalRequests": .DurationHistogram["Count"],"Percentiles":.DurationHistogram["Percentiles"][2]}' 20*
fmetric () { jq '{"Labels": .Labels,URL,StartTime,NumThreads,ActualQPS,"DurationSeconds": (.ActualDuration/1000000000),"TotalRequests": .DurationHistogram["Count"],"Percentiles":.DurationHistogram["Percentiles"][2]}' 20*; }