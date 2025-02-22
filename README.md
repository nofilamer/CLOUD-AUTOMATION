# AWS Infrastructure Automation Guide

This repository provides step-by-step instructions for setting up and managing AWS services such as Application Load Balancer (ALB), Auto Scaling Groups (ASG), and Route 53 DNS.

## Table of Contents

- [AWS Application Load Balancer (ALB)](#aws-application-load-balancer-alb)
- [AWS Auto Scaling Group (ASG)](#aws-auto-scaling-group-asg)
- [AWS Route 53 DNS](#aws-route-53-dns)
- [Managing Elastic IPs](#managing-elastic-ips)
- [Instance Metadata and User Data](#instance-metadata-and-user-data)
- [Labs & Automation](#labs--automation)
- [Cleanup and Resource Management](#cleanup-and-resource-management)
- [References](#references)

---

## AWS Application Load Balancer (ALB)

### **Overview**
AWS Application Load Balancer (ALB) operates at the application layer (OSI Layer 7) and distributes HTTP/HTTPS traffic across multiple EC2 instances. It supports:
- Path-based routing
- Host-based routing
- WebSocket support
- Integration with AWS Auto Scaling Groups

### **Creating an ALB via AWS CLI**
```sh
aws elb create-load-balancer --load-balancer-name my-alb \
  --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 \
  --security-groups sg-xxxxxxxx --subnet subnet-xxxxxxxx --region us-east-1

Registering Instances with ALB
aws elb register-instances-with-load-balancer --load-balancer-name my-alb \
  --instances i-xxxxxxxx i-yyyyyyyy --region us-east-1

Health Check Configuration
aws elb configure-health-check --load-balancer-name my-alb \
  --health-check Target=HTTP:80/,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=5

Verifying ALB Status
aws elb describe-instance-health --load-balancer-name my-alb --region us-east-1

AWS Auto Scaling Group (ASG)
Overview
AWS Auto Scaling Group (ASG) allows automatic scaling of EC2 instances based on predefined conditions, ensuring efficient resource utilization.

Creating a Launch Configuration
aws autoscaling create-launch-configuration --launch-configuration-name my-launch-config \
  --image-id ami-xxxxxxxx --instance-type t2.micro --security-groups sg-xxxxxxxx \
  --key-name my-key --user-data file://user-data-script.sh

Creating an Auto Scaling Group
aws autoscaling create-auto-scaling-group --auto-scaling-group-name my-asg \
  --launch-configuration-name my-launch-config --min-size 2 --max-size 5 \
  --desired-capacity 3 --availability-zones us-east-1a us-east-1b

Defining Scaling Policies
aws autoscaling put-scaling-policy --auto-scaling-group-name my-asg \
  --policy-name scale-up --adjustment-type ChangeInCapacity --scaling-adjustment 1 \
  --cooldown 300

Scale Down Policy
aws autoscaling put-scaling-policy --auto-scaling-group-name my-asg \
  --policy-name scale-down --adjustment-type ChangeInCapacity --scaling-adjustment -1 \
  --cooldown 300

Associating CloudWatch Alarms with Scaling Policies
Scale Up Alarm
aws cloudwatch put-metric-alarm --alarm-name HighCPU \
  --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average \
  --comparison-operator GreaterThanThreshold --threshold 80 --period 120 \
  --evaluation-periods 1 --dimensions Name=AutoScalingGroupName,Value=my-asg \
  --alarm-actions arn:aws:autoscaling:us-east-1:xxxxxxxxxxxx:scalingPolicy/scale-up

Scale Down Alarm
aws cloudwatch put-metric-alarm --alarm-name LowCPU \
  --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average \
  --comparison-operator LessThanThreshold --threshold 30 --period 120 \
  --evaluation-periods 1 --dimensions Name=AutoScalingGroupName,Value=my-asg \
  --alarm-actions arn:aws:autoscaling:us-east-1:xxxxxxxxxxxx:scalingPolicy/scale-down

AWS Route 53 DNS
Overview
Amazon Route 53 is a scalable and highly available domain name system (DNS) web service that routes end-user requests to AWS services.

Creating a Hosted Zone
aws route53 create-hosted-zone --name mydomain.com --caller-reference 20250221-123456

Listing Hosted Zones
aws route53 list-hosted-zones

Creating a DNS Record (CNAME)
aws route53 change-resource-record-sets --hosted-zone-id ZXXXXXXXXXXX \
  --change-batch '
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "app.mydomain.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "my-alb-123456.elb.amazonaws.com"}]
      }
    }
  ]
}'

Managing Elastic IPs
Allocating an Elastic IP
aws ec2 allocate-address --domain vpc

Associating an Elastic IP with an Instance
aws ec2 associate-address --instance-id i-xxxxxxxx --public-ip 52.x.x.x

Releasing an Elastic IP
aws ec2 release-address --public-ip 52.x.x.x

Instance Metadata and User Data
Retrieving Instance Metadata
curl http://169.254.169.254/latest/meta-data/

Retrieving Public Hostname
curl http://169.254.169.254/latest/meta-data/public-hostname

Executing a User Data Script on Launch
Create a user data script install-packages.sh:
#!/bin/bash
apt-get update && apt-get install -y nginx

Launch an EC2 instance with the script:
aws ec2 run-instances --image-id ami-xxxxxxxx --instance-type t2.micro \
  --key-name my-key --user-data file://install-packages.sh

Labs & Automation
Self-register EC2 Instance with Route 53
Install cli53:
wget https://github.com/barnybug/cli53/releases/download/0.8.5/cli53-linux-amd64
sudo mv cli53-linux-amd64 /usr/bin/cli53
sudo chmod +x /usr/bin/cli53

Automate DNS registration:
cli53 rrcreate mydomain.com 'myserver 60 CNAME ec2-xxxxxxxx.compute-1.amazonaws.com'

Cleanup and Resource Management
Terminate Instances
aws ec2 terminate-instances --instance-ids i-xxxxxxxx

Delete Auto Scaling Group
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name my-asg --force-delete

Delete Load Balancer
aws elb delete-load-balancer --load-balancer-name my-alb

Delete DNS Records
aws route53 change-resource-record-sets --hosted-zone-id ZXXXXXXXXXXX --change-batch '
{
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "app.mydomain.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "my-alb-123456.elb.amazonaws.com"}]
      }
    }
  ]
}'


