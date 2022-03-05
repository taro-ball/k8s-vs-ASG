#!/usr/bin/bash
set -x
mydir=`dirname "$0"`
cd $mydir
test=$(cat mytest)
type=$(echo $test | cut -d "_" -f 1)
exec >> load-${type}.log
exec 2>&1
echo $(cut -d "_" -f 1 <<< $test)
app=$(echo $test | cut -d "_" -f 2)
export AWS_DEFAULT_REGION="us-east-1"
line='=============================='

echo [$(date +%FT%T)]${line}[starting in $PWD]${line}

source 0.setup.sh
source .k8sSecrets.noupl
aws sts get-caller-identity

############# Functions #############
check_stats () {
  echo [$(date +%FT%T)]${line}[STATS]
  if [ "$1" == "asg" ]; then
    aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*]' | \
    jq --raw-output '.[]| .Instances[] | (.InstanceId, .LifecycleState, .HealthStatus, {})'
  fi
  if [ "$1" == "k8s" ]; then
    kubectl get hpa
    kubectl get deployment
    kubectl top nodes
  fi
}

############# Ready check #############
while [ -z "$mycheck" ]
do 
  if [ "$type" == "asg" ]; then
    mycheck=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text | sed 's/\s\+/\n/g' | grep myASG`
  fi
  if [ "$type" == "k8s" ]; then
    mycheck=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text | sed 's/\s\+/\n/g' | grep workers`
    
  fi
  echo [$(date +%FT%T)] waiting for instances ...
  sleep 60;
done

# wait for stack to stabilise
sleep 240

echo export t_start=$(date +%FT%T) >> metrics_vars.txt

############### Prepare to run the load test ###############
if [ "$type" == "asg" ]; then
  # get lb, asg and policy
  lb_dns=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].DNSName' --output text | sed 's/\s\+/\n/g' | grep asg`
  myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep asg`
  mypolicy_name=`aws autoscaling describe-policies --query "ScalingPolicies[*].PolicyName" --output text | sed 's/\s\+/\n/g' | grep asg`
  policy_json='{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue":'" ${cpu_perc}.0, "'"DisableScaleIn": false}'
  # set max, scale to max
  echo scaling to $max_capacity;
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${myasg} --desired-capacity $max_capacity --max-size $max_capacity
fi
if [ "$type" == "k8s" ]; then
  # log on to k8s
  aws eks update-kubeconfig --name $cluster_name
  kubectl get svc # quick check
  # get lb
  lb_dns=`kubectl get svc/${app}-svc -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
  myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep workers`
  # enable workers ASG metrics
  aws autoscaling enable-metrics-collection --auto-scaling-group-name ${myasg} --granularity "1Minute"
  # start k8s metrics collection
  nohup ./k8s-metrics.sh&
  # enable hpa 
  kubectl autoscale deployment ${app}-deployment --cpu-percent=$hpa_perc --min=1 --max=$max_pods
fi


# quick test
curl http://${lb_dns}:${warmup_url}; echo

############### LB warmup run ###############
for((i=$warmup_min_threads;i<=$warmup_max_threads;i+=1));
do
    check_stats $type
    echo [$(date +%FT%T)]${line}[WARMUP RUN c${i}]${line}
    fortio load -a -c $i -t ${warmup_cycle_sec}s -qps -1 -r 0.01 -labels "${test}-warmup-${i}" http://${lb_dns}:${warmup_url}
    check_stats $type
    sleep 60
done

aws elb describe-load-balancers
aws autoscaling describe-auto-scaling-groups

############### Performance run ###############
for((i=1;i<=3;i+=1));
do 
    sleep 60
    check_stats $type
    echo [$(date +%FT%T)]${line}[PERFORMANCE RUN ${i}]${line}
    fortio load -a -c $warmup_max_threads -t ${performance_sec}s -qps -1 -r 0.01 -labels "${test}-performance-${i}" http://${lb_dns}:${testing_url}
    check_stats $type
done

############### Performance chunck run ###############
echo [$(date +%FT%T)]${line}[PERFORMANCE 5 CHUNK RUN ${i}]${line}
sleep 60
    for((x=1;x<=5;x+=1));
    do
      check_stats $type
      fortio load -quiet -a -c $warmup_max_threads -t 60s -qps -1 -r 0.01 -labels "${test}-performance-chunk-${i}-${x}" http://${lb_dns}:${testing_url}
    # check_stats $type
    done

echo export t_scaling=$(date +%FT%T) >> metrics_vars.txt

############### Scaling run ###############
for((i=1;i<=3;i+=1));
do
    echo [$(date +%FT%T)]${line}[SCALING RUN $i: INIT]${line}
    if [ "$type" == "asg" ]; then
      # 99cpu policy to prevent immideate scaleout on historical data
      aws autoscaling put-scaling-policy --auto-scaling-group-name ${myasg} --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration '{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue": 99.0, "DisableScaleIn": false}'
      # scale to min
      echo scaling to 1;
      aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${myasg} --desired-capacity 1;
      echo [$(date +%FT%T)]${line}[SCALING RUN $i: ENABLE SCALING - SLEEP]${line}
      sleep 160;
      # back to initial policy
      aws autoscaling put-scaling-policy --auto-scaling-group-name ${myasg} --policy-name $mypolicy_name --policy-type TargetTrackingScaling --target-tracking-configuration "${policy_json}"
    fi
    if [ "$type" == "k8s" ]; then
      # delete hpa to prevent immediate scaleout on historical data
      kubectl delete horizontalpodautoscaler.autoscaling/${app}-deployment

      # scale to min
      echo scaling to 1;
      kubectl scale --replicas=1 deployment/${app}-deployment
      eksctl scale nodegroup --cluster=$cluster_name --name=standard-workers --nodes=1
      
      echo [$(date +%FT%T)]${line}[SCALING RUN $i: ENABLE SCALING - SLEEP]${line}
      sleep 160;
      # create the hpa
      kubectl autoscale deployment ${app}-deployment --cpu-percent=$hpa_perc --min=1 --max=$max_pods
      # wait for hpa to get metrics

    fi

    sleep 20 # let hpa stabilise

    echo [$(date +%FT%T)]${line}[SCALING RUN ${i}: FORTIO]${line}
    for((y=1;y<=$scaling_minutes;y+=1));
    do
      check_stats $type
      fortio load -quiet -a -c $warmup_max_threads -t 60s -qps -1 -r 0.01 -labels "${test}-scaling-${i}-${y}" http://${lb_dns}:${testing_url}
    # check_stats $type
    done
    check_stats $type
done

echo export asg_name=${myasg} >> metrics_vars.txt
echo export lb_name=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].LoadBalancerName' --output text` >> metrics_vars.txt

# wait for CloudWatch logs to catch up
sleep 300
echo export t_end=$(date +%FT%T) >> metrics_vars.txt

echo [$(date +%FT%T)]${line}[GET DATA]${line}
./2.jh-get-data.sh
echo [$(date +%FT%T)]${line}[UPLOAD $(cat 3.upload.noupl.sh | rev | cut -d "." -f 1 | rev)]${line} 
./3.upload.noupl.sh