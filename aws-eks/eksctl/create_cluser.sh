#!/bin/bash
# us-east-1 --zones=us-east-1a,us-east-1b or us-west-2
# eksctl create cluster -f cluster.yaml
eksctl create cluster --name $1 --version 1.21 --region us-east-1 --zones=us-east-1a,us-east-1b\
--nodegroup-name standard-workers --node-type t3.small \
--nodes 3 --nodes-min 1 --nodes-max 6 --managed
