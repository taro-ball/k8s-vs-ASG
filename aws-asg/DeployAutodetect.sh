#!/usr/bin/bash
aws sts get-caller-identity
vpcID=`aws ec2 describe-vpcs \
    --filters Name=isDefault,Values=true \
    --query 'Vpcs[*].VpcId' \
    --output text`

sbnt1ID=`aws ec2 describe-subnets --filters "Name=vpc-id,Values=${vpcID}"  --output text --query 'Subnets[1].SubnetId'`
sbnt2ID=`aws ec2 describe-subnets --filters "Name=vpc-id,Values=${vpcID}"  --output text --query 'Subnets[2].SubnetId'`
AMI=`aws ssm get-parameters --names '//aws\service\ami-amazon-linux-latest\amzn2-ami-hvm-x86_64-gp2' --query 'Parameters[0].[Value]' --output text`

aws cloudformation create-stack\
 --disable-rollback --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND\
 --stack-name asg-$1 --template-body file://asg-template.yaml\
 --parameters \
 ParameterKey=myVPC,ParameterValue=${vpcID}\
 ParameterKey=mySubnet1,ParameterValue=${sbnt1ID}\
 ParameterKey=mySubnet2,ParameterValue=${sbnt2ID}\
 ParameterKey=AMIimageID,ParameterValue=${AMI}\
 ParameterKey=myAPPport,ParameterValue=80