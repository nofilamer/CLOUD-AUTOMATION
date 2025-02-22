aws ec2 run-instances \
    --key-name nofil \
    --security-groups cloudperf \
    --count 1 \
    --instance-type t2.micro \
    --region us-east-1 \
    --image-id ami-0e1bed4f06a3b463d \
    --placement AvailabilityZone=us-east-1a \
    --iam-instance-profile Name=EC2 \
    --user-data file://ALBuserData.sh

aws ec2 run-instances \
    --key-name nofil \
    --security-groups cloudperf \
    --count 1 \
    --instance-type t2.micro \
    --region us-east-1 \
    --image-id ami-0e1bed4f06a3b463d \
    --placement AvailabilityZone=us-east-1c \
    --iam-instance-profile Name=EC2 \
    --user-data file://ALBuserData.sh

echo "Waiting for instance to be healthy"
sleep 5 

echo " Checking Instance ids"
INSTANCE_IDS=$(aws ec2 describe-instances  \
       	--query "Reservations[*].Instances[*].InstanceId"   \
	--output text)

echo " Registering instances to the target group"
aws elbv2 register-targets \
    --target-group-arn $(aws elbv2 describe-target-groups --names nofilALBTargetGroup --query "TargetGroups[0].TargetGroupArn" --output text) \
    --targets $(echo $INSTANCE_IDS | awk '{print "Id="$1" Id="$2}')

