aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,ImageId,Tags[*]]"
aws ssm start-session --target i-0myInstanceId