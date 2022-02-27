#!/usr/bin/bash
#set -x
mydir=`dirname "$0"`
cd $mydir
exec >> load-k8s.log
exec 2>&1
test=$(cat mytest)
export AWS_DEFAULT_REGION="us-east-1"
line='=============================='
cluster_name="C888"

echo [$(date +%FT%T)]${line}[starting in $PWD]${line}

check_stats () {
  echo [$(date +%FT%T)]${line}[STATS]
  aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*]' | jq --raw-output '.[]| .Instances[] | (.InstanceId, .LifecycleState, .HealthStatus, {})'
}
set -x
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
testing_url='3000?n=20000'
cpu_perc=35
warmup_min_threads=15
warmup_max_threads=25
warmup_cycle_sec=90
scaling_minutes=10
performance_sec=300
max_capacity=3
fi
set +x
# wait for the asg stack to come up
while [ -z "$myasg" ]
do 
myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep myASG`
echo [$(date +%FT%T)] waiting for asg...
sleep 60;
done

# wait for a bit more
sleep 90;

echo export t_start=$(date +%FT%T) >> metrics_vars.txt

# get lb, asg and policy
lb=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].DNSName' --output text | sed 's/\s\+/\n/g' | grep asg`
myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep asg`
mypolicy_name=`aws autoscaling describe-policies --query "ScalingPolicies[*].PolicyName" --output text | sed 's/\s\+/\n/g' | grep asg`
policy_json='{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue":'" ${cpu_perc}.0, "'"DisableScaleIn": false}'

# set max, scale to max
echo scaling to $max_capacity;
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $myasg --desired-capacity $max_capacity --max-size $max_capacity

# set initial policy to keep instance count up
aws autoscaling put-scaling-policy --auto-scaling-group-name $myasg --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration '{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue": 1.0, "DisableScaleIn": false}'

# quick test
curl http://$lb:$warmup_url; echo

# LB warmup
for((i=$warmup_min_threads;i<=$warmup_max_threads;i+=1));
do
    check_stats
    echo [$(date +%FT%T)]${line}[WARMUP RUN c${i}]${line}
    fortio load -a -c $i -t ${warmup_cycle_sec}s -qps -1 -r 0.01 -labels "$test-warmup-${i}" http://$lb:$warmup_url
    check_stats
    sleep 60
done

# performance
for((i=1;i<=3;i+=1));
do 
    sleep 60
    check_stats
    echo [$(date +%FT%T)]${line}[PERFORMANCE RUN ${i}]${line}
    fortio load -a -c $warmup_max_threads -t ${performance_sec}s -qps -1 -r 0.01 -labels "$test-performance-${i}" http://$lb:$testing_url
    check_stats
done

echo export t_scaling=$(date +%FT%T) >> metrics_vars.txt
# scaling
for((i=1;i<=3;i+=1));
do
    echo [$(date +%FT%T)]${line}[SCALING DOWN]${line}
    # 99cpu policy to prevent immideate scaleout on historical data
    aws autoscaling put-scaling-policy --auto-scaling-group-name $myasg --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration '{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue": 99.0, "DisableScaleIn": false}'

	# scale to min
    echo scaling to 1;
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name $myasg --desired-capacity 1;
    echo [$(date +%FT%T)]${line}[ENABLE SCALING - SLEEP]${line}
    sleep 180;
        # back to initial policy
        aws autoscaling put-scaling-policy --auto-scaling-group-name $myasg --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration "$policy_json"
    
    echo [$(date +%FT%T)]${line}[SCALING RUN ${i}]${line}
    for((y=1;y<=$scaling_minutes;y+=1));
    do
    check_stats
    fortio load -quiet -a -c $warmup_max_threads -t 60s -qps -1 -r 0.01 -labels "$test-scaling-${i}-${y}" http://$lb:$testing_url
    # check_stats
    done
    check_stats
done
# note
# date -d "+ 10 minutes" +%FT%T
echo export t_end=$(date +%FT%T) >> metrics_vars.txt
echo export asg_name=$myasg >> metrics_vars.txt
echo export lb_name=$(echo $lb | cut -d "-" -f 1) >> metrics_vars.txt

# wait for CloudWatch logs to catch up
sleep 600
echo [$(date +%FT%T)]${line}[GET DATA]${line}
./2.jh-get-data.sh
echo [$(date +%FT%T)]${line}[UPLOAD $(cat 3.upload.noupl.sh | rev | cut -d "." -f 1 | rev)]${line} 
./3.upload.noupl.sh