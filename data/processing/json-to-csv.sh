#!/bin/bash
jq -r '.MetricDataResults[] | ([.Timestamps, .Values] | transpose[]) + [.Id] | @csv' asg_data.json > asg_data.csv
jq -r '.MetricDataResults[] | ([.Timestamps, .Values] | transpose[]) + [.Id] | @csv' alb_data.json > alb_data.csv