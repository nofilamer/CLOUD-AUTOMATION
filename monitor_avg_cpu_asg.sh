aws cloudwatch get-metric-statistics \
    --namespace "AWS/EC2" \
    --metric-name "CPUUtilization" \
    --dimensions Name=AutoScalingGroupName,Value=nofilASG \
    --statistics Average \
    --period 300 \
    --start-time $(date -u -d '-10 minutes' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --output table

