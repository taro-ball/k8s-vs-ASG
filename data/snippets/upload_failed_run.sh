upload failed run:

export AWS_DEFAULT_REGION="us-east-1"

myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g'` # | grep workers`
or
myasg=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text| sed 's/\s\+/\n/g' | grep asg`

echo export asg_name=${myasg} >> metrics_vars.txt
echo export lb_name=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].LoadBalancerName' --output text` >> metrics_vars.txt
echo export t_end=$(date +%FT%T) >> metrics_vars.txt
cat metrics_vars.txt


./2.jh-get-data.sh
find . -maxdepth 1 -type f -size +500k -exec zip -m9 backup {} \;
./3.upload.noupl.sh