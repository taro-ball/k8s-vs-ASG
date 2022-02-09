#!/usr/bin/bash

warmup_url='$warmup_url'
testing_url='$testing_url'

echo start warmup: $(date) >> dates.txt
set -x

region_param='--region us-east-1'

lb=`aws elb describe-load-balancers $region_param --query 'LoadBalancerDescriptions[*].DNSName' --output text | sed 's/\s\+/\n/g' | grep asg`
cd;pwd; curl $lb:3000; echo

# scale to max
myasg=`aws autoscaling describe-auto-scaling-groups $region_param --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep asg`
echo scaling to 4;
aws autoscaling update-auto-scaling-group $region_param --auto-scaling-group-name $myasg --desired-capacity 4

# LB warmup
for((i=15;i<=25;i+=1)); do fortio load -a -c $i -t 45s -qps -1 -r 0.01 -labels "warmup" http://$lb:$warmup_url; done

# performance
for((i=1;i<=3;i+=1)); do sleep 60; fortio load -a -c 20 -t 300s -qps -1 -r 0.01 -labels "performance-${i}" http://$lb:$testing_url; done

echo start scaling: $(date) >> dates.txt
# scaling
for((i=1;i<=3;i+=1));
do
	# scale to min
    mypolicy=`aws autoscaling describe-policies $region_param --query "ScalingPolicies[*].PolicyName" --output text | sed 's/\s\+/\n/g' | grep asg`

    #aws autoscaling put-scaling-policy --auto-scaling-group-name $myasg --policy-name $mypolicy --policy-type TargetTrackingScaling --target-tracking-configuration file://scaling-policy99.json

    aws autoscaling put-scaling-policy $region_param --auto-scaling-group-name $myasg --policy-name $mypolicy --policy-type TargetTrackingScaling --target-tracking-configuration '{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue": 99.0, "DisableScaleIn": false}'

    echo scaling to 1;
    aws autoscaling update-auto-scaling-group $region_param --auto-scaling-group-name $myasg --desired-capacity 1;
    
    sleep 180;

        aws autoscaling put-scaling-policy $region_param --auto-scaling-group-name $myasg --policy-name $mypolicy --policy-type TargetTrackingScaling --target-tracking-configuration '{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue": 35.0, "DisableScaleIn": false}'

    fortio load -a -c 20 -t 780s -qps -1 -r 0.01 -labels "scaling-${i}" http://$lb:$testing_url
done
echo end: $(date) >> dates.txt




