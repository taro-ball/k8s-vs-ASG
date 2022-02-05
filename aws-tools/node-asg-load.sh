#!/usr/bin/bash
lb=`aws elb describe-load-balancers --region us-east-1 --query 'LoadBalancerDescriptions[*].DNSName' --output text | sed 's/\s\+/\n/g' | grep asg`
echo $lb;cd;pwd; curl $lb:3000

# scale to max
myasg=`aws autoscaling describe-auto-scaling-groups --region us-east-1 --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep asg`
echo scaling to 4;
aws autoscaling update-auto-scaling-group --region us-east-1 --auto-scaling-group-name $myasg --desired-capacity 4

# LB warmup
for((i=15;i<=25;i+=1)); do fortio load -a -c $i -t 30s -qps -1 -r 0.01 -labels "warmup" http://$lb:3000?n=5555; done

# performance
for((i=1;i<=3;i+=1)); do echo sleep 60; sleep 60; fortio load -a -c 20 -t 300s -qps -1 -r 0.01 -labels "performance-${i}" http://$lb:3000?n=9999; done

# scaling
for((i=1;i<=3;i+=1))
do
	# scale to min
    echo scaling to 1;
    aws autoscaling update-auto-scaling-group --region us-east-1 --auto-scaling-group-name $myasg --desired-capacity 1;
    echo sleep 120;sleep 120;
    fortio load -a -c 20 -t 780s -qps -1 -r 0.01 -labels "scaling-${i}" http://$lb:3000?n=9999
done





