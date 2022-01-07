#!/bin/bash
aws cloudwatch get-metric-data --cli-input-json file://alb.json --region us-east-1 > alb_data.json
aws cloudwatch get-metric-data --cli-input-json file://asg.json --region us-east-1 > asg_data.json

# get results
sudo zip -r /var/www/html/foo.zip .

# then you can point Ur browser to:
# http://100.26.180.59/foo.zip