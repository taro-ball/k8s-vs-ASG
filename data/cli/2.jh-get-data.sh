#!/usr/bin/bash
source dates.txt

envsubst < alb-query-template.json > alb-query.json
envsubst < asg-query-template.json > asg-query.json

# get CloudWatch metrics
aws cloudwatch get-metric-data --cli-input-json file://alb-query.json --region us-east-1 > alb_data.json
aws cloudwatch get-metric-data --cli-input-json file://asg-query.json --region us-east-1 > asg_data.json
