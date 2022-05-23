#!/bin/bash
export AWS_ACCESS_KEY_ID=$1
export AWS_SECRET_ACCESS_KEY=$2
export username=ad1
aws sts get-caller-identity

aws iam create-user --user-name $username

aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --user-name $username

creds=`aws iam create-access-key --user-name $username`
echo $creds

echo -e "[default]\naws_access_key_id=`echo $creds | jq -r ".AccessKey.AccessKeyId"`" > ~/.aws/credentials
echo -e "aws_secret_access_key=`echo $creds | jq -r ".AccessKey.SecretAccessKey"` \n#$(date)" >> ~/.aws/credentials
