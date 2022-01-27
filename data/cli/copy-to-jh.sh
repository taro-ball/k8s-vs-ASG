#!/bin/bash
ip=`aws ec2 describe-instances --filters Name=tag-value,Values=jumphost-1 --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`
echo copying to $ip
scp -o StrictHostKeyChecking=no -i ../../.exclDEV-Key.pem -r $PWD/ ec2-user@${ip}:/tmp

# and back
ip=`aws ec2 describe-instances --filters Name=tag-value,Values=jumphost-1 --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`
mydate=$(date +"%Y-%m-%d-%H-%M")
echo copying from $ip to $mydate
mkdir ~/run${mydate}
scp -o StrictHostKeyChecking=no -i ../../.exclDEV-Key.pem -r ec2-user@${ip}:/tmp/cli ~/run${mydate}