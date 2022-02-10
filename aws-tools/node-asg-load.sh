#!/usr/bin/bash

app="apache"

if [ "$app" == "apache" ]; then
warmup_url='80/test.html'
testing_url='80/test.html'
cpu_perc=70
warmup_min_threads=80
warmup_max_threads=90
warmup_cycle_sec=60
fi

if [ "$app" == "node" ]; then
warmup_url='3000?n=5555'
testing_url='3000?n=9999'
cpu_perc=35
warmup_min_threads=15
warmup_max_threads=25
warmup_cycle_sec=60
fi

echo start warmup: $(date) >> dates.txt
set -x

region_param='--region us-east-1'

# get lb, asg and policy
lb=`aws elb describe-load-balancers $region_param --query 'LoadBalancerDescriptions[*].DNSName' --output text | sed 's/\s\+/\n/g' | grep asg`
myasg=`aws autoscaling describe-auto-scaling-groups $region_param --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep asg`
mypolicy_name=`aws autoscaling describe-policies $region_param --query "ScalingPolicies[*].PolicyName" --output text | sed 's/\s\+/\n/g' | grep asg`
policy_json='{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue":'" ${cpu_perc}.0, "'"DisableScaleIn": false}'
# scale to max
echo scaling to 4;
aws autoscaling update-auto-scaling-group $region_param --auto-scaling-group-name $myasg --desired-capacity 4

# set initial policy
aws autoscaling put-scaling-policy $region_param --auto-scaling-group-name $myasg --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration "$policy_json"

# quick test
cd;pwd; curl http://$lb:$warmup_url; echo

# LB warmup
for((i=$warmup_min_threads;i<=$warmup_max_threads;i+=1)); do fortio load -a -c $i -t ${warmup_cycle_sec}s -qps -1 -r 0.01 -labels "warmup" http://$lb:$warmup_url; done

# performance
for((i=1;i<=3;i+=1)); do sleep 60; fortio load -a -c $warmup_max_threads -t 300s -qps -1 -r 0.01 -labels "performance-${i}" http://$lb:$testing_url; done

echo start scaling: $(date) >> dates.txt
# scaling
for((i=1;i<=3;i+=1));
do

    # 99cpu policy to prevent scaleout on historical data
    aws autoscaling put-scaling-policy $region_param --auto-scaling-group-name $myasg --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration '{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue": 99.0, "DisableScaleIn": false}'

	# scale to min
    echo scaling to 1;
    aws autoscaling update-auto-scaling-group $region_param --auto-scaling-group-name $myasg --desired-capacity 1;
    
    sleep 180;
        # pack to initial policy
        aws autoscaling put-scaling-policy $region_param --auto-scaling-group-name $myasg --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration "$policy_json"

    fortio load -a -c $warmup_max_threads -t 780s -qps -1 -r 0.01 -labels "scaling-${i}" http://$lb:$testing_url
done
echo end: $(date) >> dates.txt




