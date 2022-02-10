#!/bin/bash
ip=`aws ec2 describe-instances --filters Name=tag-value,Values=jumphost-1 --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`
echo copying to $ip
# remember to `cd data/cli`
sed -i -r 's/(\b[0-9]{1,3}\.){3}[0-9]{1,3}\b'/"$ip"/ /c/Users/pa/.ssh/config
scp -o StrictHostKeyChecking=no -r $PWD/ ec2-user@${ip}:/tmp
# if no ssh config then set key explicitly: -i ../../.exclDEV-Key.pem
# then
# on jh (eg from vsode terminal)
sudo chmod -R a+rw /tmp/
sudo sh -c "cp -r /home/ssm-user/* /tmp/cli"

# and back
ip=`aws ec2 describe-instances --filters Name=tag-value,Values=jumphost* --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`
mydate=$(date +"%Y-%m-%d-%H-%M")
echo copying from $ip to $mydate
mkdir ~/run${mydate}
scp -o StrictHostKeyChecking=no -i ../../.exclDEV-Key.pem -r ec2-user@${ip}:/tmp/cli ~/run${mydate}

