#!/bin/bash

autotest=$1
if  [ -z "$1" ]; then
cat data/cli/1.load-asg.sh data/cli/1.load-k8s.sh | egrep 'asg_|k8s_'
read -p "No test specified. Press enter to deploy all, ctrl+c to abort."
#autotest=k8s_node3
fi

set -x

# if not using default profile
source .exclAuthenticate.sh

# write new key only if successful
pem=$(aws ec2 create-key-pair --key-name dev-key) && echo "$pem" | jq --raw-output '.KeyMaterial' > .exclDEV-Key.pem

cd aws-tools
./deployJumpHost.sh 1 $autotest
cd ..

if  [ "${autotest:0:3}" != "k8s" ]; then
cd aws-asg
./DeployAutodetect.sh 1 $autotest
cd ..
fi

if  [ "${autotest:0:3}" != "asg" ]; then
eksctl create cluster -f eksctl/Cgenerated.yml
cd k8s
./apply-k8s.sh $autotest
cd ..
fi









# cmd="google-chrome";
# eval "${cmd}" &>.exclOutput.log & disown;