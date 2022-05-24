# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-windows
aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,ImageId,Tags[*]]" | grep -b 10 jumphost
aws ssm start-session --target i-0myInstanceId