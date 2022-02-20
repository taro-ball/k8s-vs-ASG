#!/usr/bin/bash
set -x
exec >> load-asg.log
exec 2>&1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
dirname "$0"

test=$(cat mytest)
echo export t_start=$(date +%FT%T) >> dates.txt
export AWS_DEFAULT_REGION=us-east-1

if [ "$test" == "asg_apache3" ]; then
warmup_url='80/test.html'
testing_url='80/test.html'
cpu_perc=70
warmup_min_threads=65
warmup_max_threads=75
warmup_cycle_sec=120
scaling_sec=800
max_capacity=3
fi

if [ "$test" == "asg_node3" ]; then
warmup_url='3000?n=5555'
testing_url='3000?n=9999'
cpu_perc=35
warmup_min_threads=15
warmup_max_threads=25
warmup_cycle_sec=60
scaling_sec=750
max_capacity=3
fi

# wait for the asg stack to come up
sleep 600

echo export t_start=$(date +%FT%T) >> dates.txt

region_param='--region us-east-1'

# get lb, asg and policy
lb=`aws elb describe-load-balancers $region_param --query 'LoadBalancerDescriptions[*].DNSName' --output text | sed 's/\s\+/\n/g' | grep asg`
myasg=`aws autoscaling describe-auto-scaling-groups $region_param --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep asg`
mypolicy_name=`aws autoscaling describe-policies $region_param --query "ScalingPolicies[*].PolicyName" --output text | sed 's/\s\+/\n/g' | grep asg`
policy_json='{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue":'" ${cpu_perc}.0, "'"DisableScaleIn": false}'

# set max, scale to max
echo scaling to $max_capacity;
aws autoscaling update-auto-scaling-group $region_param --auto-scaling-group-name $myasg --desired-capacity $max_capacity --max-size $max_capacity

# set initial policy to keep instance count up
aws autoscaling put-scaling-policy $region_param --auto-scaling-group-name $myasg --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration '{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue": 1.0, "DisableScaleIn": false}'

# quick test
pwd; curl http://$lb:$warmup_url; echo

# LB warmup
for((i=$warmup_min_threads;i<=$warmup_max_threads;i+=1)); do fortio load -a -c $i -t ${warmup_cycle_sec}s -qps -1 -r 0.01 -labels "$app-warmup" http://$lb:$warmup_url; sleep 60 ; done

# performance
for((i=1;i<=3;i+=1)); do sleep 60; fortio load -a -c $warmup_max_threads -t 300s -qps -1 -r 0.01 -labels "$app-performance-${i}" http://$lb:$testing_url; done

echo export t_scaling=$(date +%FT%T) >> dates.txt
# scaling
for((i=1;i<=3;i+=1));
do

    # 99cpu policy to prevent immideate scaleout on historical data
    aws autoscaling put-scaling-policy $region_param --auto-scaling-group-name $myasg --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration '{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue": 99.0, "DisableScaleIn": false}'

	# scale to min
    echo scaling to 1;
    aws autoscaling update-auto-scaling-group $region_param --auto-scaling-group-name $myasg --desired-capacity 1;
    
    sleep 180;
        # back to initial policy
        aws autoscaling put-scaling-policy $region_param --auto-scaling-group-name $myasg --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration "$policy_json"

    fortio load -a -c $warmup_max_threads -t ${scaling_sec}s -qps -1 -r 0.01 -labels "$app-scaling-${i}" http://$lb:$testing_url
done
# note
# date -d "+ 10 minutes" +%FT%T
echo export t_end=$(date +%FT%T) >> dates.txt

# wait for CloudWatch logs to catch up
sleep 600
./2.jh-get-data.sh
./3.upload.noupl.sh