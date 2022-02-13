#!/bin/bash
jq -r '.MetricDataResults[] | ([.Timestamps, .Values] | transpose[]) + [.Id] | @csv'