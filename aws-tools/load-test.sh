#!/bin/bash
set -x

# -a : save result
# -c 150: number of threads
# -n 10000000: total number of requests
# -qps -1: max queries per second
# -r 0.01: Resolution of the histogram lowest buckets in seconds

kubectl get svc
alb=`aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[*].DNSName' --output text | grep asg`
echo $alb;cd;pwd; curl $alb:88/test.html
fortio load -a -c 50 -n 2000000 -qps -1 -r 0.01 -labels "hpa24 etc" http://$alb:88/test.html
fortio load -a -c 80 -t 600s -qps -1 -r 0.01 http://$alb:88/test.html

# quick check
egrep -rni QPS\|Threads\|Count *

# proper check
jq '{"URL": .Labels,StartTime,NumThreads,ActualQPS,\
"DurationSeconds": (.ActualDuration/1000000000),"TotalRequests": .DurationHistogram["Count"], \
"Percentiles":.DurationHistogram["Percentiles"][2]}' 2*


# jq '{"URL": .Labels,StartTime,NumThreads,ActualQPS,"DurationSeconds": (.ActualDuration/1000000000),"TotalRequests": .DurationHistogram["Count"],"Percentiles":.DurationHistogram["Percentiles"][2]}' 2*