#!/bin/bash
OWNER=jacob.borella
EXPIRE_ON=2022-06-29
INSTANCE_NAME='Jacob Borella Tradecraft Mission17'

aws ec2 run-instances --image-id ami-0a8dc52684ee2fee2 \
--count 1 \
--instance-type t3.medium \
--key-name jlp-tradecraft \
--security-group-ids sg-03137660eeec9dfcc \
--subnet-id subnet-15a54663 \
--block-device-mappings '[{"DeviceName": "/dev/xvdb", "Ebs": {"DeleteOnTermination": true, "Iops": 500, "VolumeSize": 20, "VolumeType": "io1"}}, {"DeviceName": "/dev/xvda", "Ebs": {"DeleteOnTermination": true, "VolumeSize": 8, "VolumeType": "gp2"}}]' \
--tag-specification "ResourceType=instance,Tags=[{Key=Name,  Value=$INSTANCE_NAME}, {Key=owner,Value=$OWNER},{Key=expire-on,Value=$EXPIRE_ON}]"

unset MACHINE_IP
MACHINE_IP=$(aws ec2 describe-instances --filters "Name=tag:owner,Values=$OWNER" "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running" | jq -r '.Reservations[].Instances[]  | .PublicIpAddress')

#try until the machine is running
RETRIES=100
while [ $RETRIES -gt 0 ]
do
RETRIES=$(( $RETRIES - 1 ))
MACHINE_IP=$(aws ec2 describe-instances --filters "Name=tag:owner,Values=$OWNER" "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running" | jq -r '.Reservations[].Instances[]  | .PublicIpAddress')
if [ ${#MACHINE_IP} -eq 0 ]; 
then echo "waiting for machine to come up"; sleep 5;
else echo "machine available at '$MACHINE_IP'"; break;
fi
done

#then wait for ssh
wait_for_ssh() {
RETRIES=100
while [ $RETRIES -gt 0 ]
do
RETRIES=$(( $RETRIES - 1 ))
ROOT_DIR=$(ssh -o "StrictHostKeyChecking=no" -o "ConnectTimeout=1" -o "BatchMode=yes" -i ~/.ssh/jlp-tradecraft.pem ec2-user@$MACHINE_IP pwd)
if [ -z $ROOT_DIR ] || [ $ROOT_DIR != '/home/ec2-user' ]; 
then echo "waiting for ssh to come up"; sleep 5;
else echo "ssh available at '$MACHINE_IP'"; break;
fi
done
}

wait_for_ssh

#run install script for docker
scp -o "StrictHostKeyChecking=no" -i ~/.ssh/jlp-tradecraft.pem install_docker.sh ec2-user@$MACHINE_IP:
ssh -o "StrictHostKeyChecking=no" -i ~/.ssh/jlp-tradecraft.pem ec2-user@$MACHINE_IP ./install_docker.sh

wait_for_ssh


#run install script for kubernetes
scp -o "StrictHostKeyChecking=no" -i ~/.ssh/jlp-tradecraft.pem install_k8s.sh ec2-user@$MACHINE_IP:
ssh -o "StrictHostKeyChecking=no" -i ~/.ssh/jlp-tradecraft.pem ec2-user@$MACHINE_IP ./install_k8s.sh

wait_for_ssh

#run install script for jq
scp -o "StrictHostKeyChecking=no" -i ~/.ssh/jlp-tradecraft.pem install_jq.sh ec2-user@$MACHINE_IP:
ssh -o "StrictHostKeyChecking=no" -i ~/.ssh/jlp-tradecraft.pem ec2-user@$MACHINE_IP ./install_jq.sh

echo "Host is ready. Access with: "
echo "ssh ec2-user@$MACHINE_IP"
echo "To start minikube:"
echo "minikube start"
echo "Verify with:"
echo "kubectl get po -A"

echo "For more info https://minikube.sigs.k8s.io/docs/start/"

