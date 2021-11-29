#!/usr/bin/bash
aws sts get-caller-identity
vpcID=`aws ec2 describe-vpcs \
    --filters Name=isDefault,Values=true \
    --query 'Vpcs[*].VpcId' \
    --output text`

sbntID=`aws ec2 describe-subnets --output text --query 'Subnets[0].SubnetId'`

echo $vpcID $sbntID