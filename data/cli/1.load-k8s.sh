#!/usr/bin/bash
#set -x
mydir=`dirname "$0"`
cd $mydir
exec >> load-k8s.log
exec 2>&1
echo [$(date +%FT%T)]${line}[starting in $PWD]${line}

test=$(cat mytest)
export AWS_DEFAULT_REGION="us-east-1"
line='=============================='
cluster_name="C888"


check_stats () {
  echo [$(date +%FT%T)]${line}[STATS]
  kubectl get hpa
  kubectl get deployment
  kubectl top nodes
}
set -x # print variables
if [ "$test" == "k8s_apache3" ]; then
warmup_url='80/test.html'
testing_url='80/test.html'
cpu_perc=70
warmup_min_threads=65
warmup_max_threads=75
warmup_cycle_sec=120
scaling_sec=800
performance_sec=300
max_capacity=3
fi

if [ "$test" == "k8s_node3" ]; then
warmup_url='3000?n=5555'
testing_url='3000?n=20000'
hpa_perc=70
warmup_min_threads=15
warmup_max_threads=25
warmup_cycle_sec=90
scaling_sec=800
performance_sec=300
max_pods=6
max_nodes=3
fi
set +x
# authenticate
source .k8sSecrets.noupl
aws sts get-caller-identity

# wait for the k8s stack to come up
while [ -z "$myasg" ]
do 
myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep workers`
echo [$(date +%FT%T)] waiting for nodes ...
sleep 60;
done

# wait for a bit more - it takes some time for service to become available
sleep 240
echo export t_start=$(date +%FT%T) >> metrics_vars.txt

# log on to k8s
aws eks update-kubeconfig --region us-east-1 --name $cluster_name 
kubectl get svc
# get lb
lb=`kubectl get svc/taro-svc -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
aws elb describe-load-balancers

# set max, scale to max
echo [$(date +%FT%T)]${line}[scaling cluster to $max_nodes and deployment to $max_pods pods]
# we don't want hpa to scale down the deployment, so delete it for now
kubectl delete horizontalpodautoscaler.autoscaling/taro-deployment
# scale k8s deployment to max
kubectl scale --replicas=$max_pods deployment/taro-deployment
# scale k8s nodes to max
eksctl scale nodegroup --cluster=$cluster_name --name=standard-workers --nodes=$max_nodes --nodes-max=$max_nodes

# enable workers ASG metrics
myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep workers`
aws autoscaling enable-metrics-collection --auto-scaling-group-name $myasg --granularity "1Minute"

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
    # delete hpa to prevent immediate scaleout on historical data
    kubectl delete horizontalpodautoscaler.autoscaling/taro-deployment

	# scale to min
    echo scaling to 1;
    kubectl scale --replicas=1 deployment/taro-deployment
    eksctl scale nodegroup --cluster=$cluster_name --name=standard-workers --nodes=1
    
    echo [$(date +%FT%T)]${line}[SCALING HPA - SLEEP]${line}
    sleep 160;
    # create the hpa
    kubectl autoscale deployment taro-deployment --cpu-percent=$hpa_perc --min=1 --max=$max_pods
    # wait for hpa to get metrics
    sleep 20

    check_stats
    echo [$(date +%FT%T)]${line}[SCALING RUN ${i}]${line}
    fortio load -a -c $warmup_max_threads -t ${scaling_sec}s -qps -1 -r 0.01 -labels "$test-scaling-${i}" http://$lb:$testing_url
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