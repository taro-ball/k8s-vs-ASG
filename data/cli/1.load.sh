#!/usr/bin/bash
#set -x
mydir=`dirname "$0"`
cd $mydir
exec >> load-asg.log
exec 2>&1
test=$(cat mytest)
type=${test:0:3}
export AWS_DEFAULT_REGION="us-east-1"
line='=============================='

echo [$(date +%FT%T)]${line}[starting in $PWD]${line}

source 0.setup.sh
source .k8sSecrets.noupl
aws sts get-caller-identity

# ready check
while [ -z "$myasg" ]
do 
  if [ "$type" == "asg" ]; then
    myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text | sed 's/\s\+/\n/g' | grep myASG`
  fi
  if [ "$type" == "k8s" ]; then
    myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text | sed 's/\s\+/\n/g' | grep workers`
    
  fi
  echo [$(date +%FT%T)] waiting for instances ...
  sleep 60;
done
fi

# wait for stack to stabilise
sleep 240

echo export t_start=$(date +%FT%T) >> metrics_vars.txt

if [ "$type" == "asg" ]; then
  # get lb, asg and policy
  lb=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].DNSName' --output text | sed 's/\s\+/\n/g' | grep asg`
  myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep asg`
  mypolicy_name=`aws autoscaling describe-policies --query "ScalingPolicies[*].PolicyName" --output text | sed 's/\s\+/\n/g' | grep asg`
  policy_json='{ "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" }, "TargetValue":'" ${cpu_perc}.0, "'"DisableScaleIn": false}'
fi
if [ "$type" == "k8s" ]; then
  # log on to k8s
  aws eks update-kubeconfig --name $cluster_name
  kubectl get svc # quick check
  # get lb
  lb=`kubectl get svc/taro-svc -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
  # start k8s metrics collection
  nohup ./k8s-metrics.sh&
fi

############# FUNCTIONS #############
check_stats (type) {
  echo [$(date +%FT%T)]${line}[STATS]
  if [ "$type" == "asg" ]; then
    aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*]' | \
    jq --raw-output '.[]| .Instances[] | (.InstanceId, .LifecycleState, .HealthStatus, {})'
  fi
  if [ "$type" == "k8s" ]; then
    kubectl get hpa
    kubectl get deployment
    kubectl top nodes
  fi
}
