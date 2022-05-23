#!/bin/bash
export AWS_ACCESS_KEY_ID=$1
export AWS_SECRET_ACCESS_KEY=$2

aws sts get-caller-identity

aws iam create-user --user-name ad

aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --user-name ad

creds=`aws iam create-access-key --user-name ad`

echo export AWS_ACCESS_KEY_ID=`echo $creds | jq ".AccessKey.AccessKeyId"` > .exclAuthenticate.sh
echo export AWS_SECRET_ACCESS_KEY=`echo $creds | jq ".AccessKey.SecretAccessKey"` >> .exclAuthenticate.sh
