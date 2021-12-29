#!/bin/bash
set -x

# -a : save result
# -c 150: number of threads
# -n 10000000: total number of requests
# -qps -1: max queries per second
# -r 0.01: Resolution of the histogram lowest buckets in seconds

aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[*].DNSName' --output text

fortio load -a -c 50 -n 2000000 -qps -1 -r 0.01 http://localhost:88/test.html
fortio load -a -c 120 -t 600s -qps -1 -r 0.01 http://localhost:88/test.html