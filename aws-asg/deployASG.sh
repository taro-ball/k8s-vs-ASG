#!/usr/bin/bash
aws sts get-caller-identity
vpcID=`aws ec2 describe-vpcs \
    --filters Name=isDefault,Values=true \
    --query 'Vpcs[*].VpcId' \
    --output text`

sbnt1ID=`aws ec2 describe-subnets --filters "Name=vpc-id,Values=${vpcID}"  --output text --query 'sort_by(Subnets, &AvailabilityZone)[0].SubnetId'`
sbnt2ID=`aws ec2 describe-subnets --filters "Name=vpc-id,Values=${vpcID}"  --output text --query 'sort_by(Subnets, &AvailabilityZone)[1].SubnetId'`
#AMI=`aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-2.0.20220218.3-x86_64-gp2" --query 'Images[0].[ImageId]' --output text`
AMI=`aws ssm get-parameters --names '//aws\service\ami-amazon-linux-latest\amzn2-ami-hvm-x86_64-gp2' --query 'Parameters[0].[Value]' --output text`

set -x

aws cloudformation create-stack\
 --disable-rollback --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND\
 --stack-name asg-$1 --template-body file://asg-template-classicELB.yaml\
 --parameters \
 ParameterKey=myVPC,ParameterValue=${vpcID}\
 ParameterKey=mySubnet1,ParameterValue=${sbnt1ID}\
 ParameterKey=mySubnet2,ParameterValue=${sbnt2ID}\
 ParameterKey=AMIimageID,ParameterValue=${AMI} \
 ParameterKey=autotest,ParameterValue=$2
 #ParameterKey=myAPPport,ParameterValue=3000