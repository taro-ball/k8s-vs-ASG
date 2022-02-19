#!/bin/bash
set -x

# if not usinf default profile
source .exclAuthenticate.sh

# write new key only if successful
pem=$(aws ec2 create-key-pair --key-name dev-key) && echo "$pem" | jq --raw-output '.KeyMaterial' > .exclDEV-Key.pem

cd aws-tools
./deployJumpHost.sh 1
cd ..

cd aws-asg
# ./DeployAutodetect.sh 1
cd ..

eksctl create cluster -f eksctl/Cgenerated.yml
# aws autoscaling enable-metrics-collection --granularity "1Minute"\
# --auto-scaling-group-name eks-standard-workers-6cbebf48-a237-a098-d806-aca2cd29c35e


cd k8s
./apply-k8s.sh

# cmd="google-chrome";
# eval "${cmd}" &>.exclOutput.log & disown;