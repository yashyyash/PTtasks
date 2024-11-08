#!/bin/bash

# Set the CloudWatch namespace and metric names
namespace="CustomAppMetrics"
metric_name="ResponseTime"
metric_name_2="RequestCount"
metric_name_3="ErrorCount"
metric_name_4="CPUUsage"
metric_name_5="MemoryUsage"

# Manually set the EC2 instance ID
instance_id="i-009abcc462d996efd"

# Log file path
log_file="/home/ubuntu/phpappmonitor.log"

# Log the current timestamp and action
echo "Running script at $(date)" >> "$log_file"

# Measure the response time of your PHP app
start_time=$(date +%s%3N)  # Capture the current timestamp in milliseconds
http_code=$(curl -s -o /dev/null -w "%{http_code}" http://3.81.166.101/app.php)  # Capture HTTP status code
end_time=$(date +%s%3N)    # Capture the timestamp after the request

# Calculate the response time in milliseconds
response_time=$((end_time - start_time))

# Log response time and HTTP status code
echo "Response Time: $response_time ms, HTTP Code: $http_code" >> "$log_file"

# Send the response time to CloudWatch
aws cloudwatch put-metric-data --namespace "$namespace" --metric-name "$metric_name" --dimensions InstanceId="$instance_id" --value "$response_time" --unit Milliseconds

# Track HTTP requests and errors (e.g., 500 errors)
if [[ "$http_code" -ge 500 ]]; then
  aws cloudwatch put-metric-data --namespace "$namespace" --metric-name "$metric_name_3" --dimensions InstanceId="$instance_id" --value 1 --unit Count
  echo "Error: HTTP $http_code - Sending ErrorCount metric to CloudWatch" >> "$log_file"
else
  aws cloudwatch put-metric-data --namespace "$namespace" --metric-name "$metric_name_2" --dimensions InstanceId="$instance_id" --value 1 --unit Count
  echo "Request successful: HTTP $http_code - Sending RequestCount metric to CloudWatch" >> "$log_file"
fi

# Get CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# Get Memory usage
mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

# Send CPU usage to CloudWatch
aws cloudwatch put-metric-data --namespace "$namespace" --metric-name "$metric_name_4" --dimensions InstanceId="$instance_id" --value "$cpu_usage" --unit Percent

# Send Memory usage to CloudWatch
aws cloudwatch put-metric-data --namespace "$namespace" --metric-name "$metric_name_5" --dimensions InstanceId="$instance_id" --value "$mem_usage" --unit Percent

# Log that the script has finished
echo "Script execution completed at $(date)" >> "$log_file"

