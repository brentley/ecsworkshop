---
title: "Embedded tab content"
disableToc: true
hidden: true
---

## Increase the disk size on the Cloud9 instance

```bash
export instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
python -c "import boto3
import os
from botocore.exceptions import ClientError 
ec2 = boto3.client('ec2')
volume_info = ec2.describe_volumes(
    Filters=[
        {
            'Name': 'attachment.instance-id',
            'Values': [
                os.getenv('instance_id')
            ]
        }
    ]
)
volume_id = volume_info['Volumes'][0]['VolumeId']
try:
    resize = ec2.modify_volume(    
            VolumeId=volume_id,    
            Size=30
    )
    print(resize)
except ClientError as e:
    if e.response['Error']['Code'] == 'InvalidParameterValue':
        print('ERROR MESSAGE: {}'.format(e))"
sudo reboot

```

- *Note*: The above command is adding more disk space to the root volume of the EC2 instance that Cloud9 runs on. Once the command completes, we reboot the instance which could take a minute or two for the IDE to come back online.

## Install and setup prerequisites

```
# Install prerequisite packages
sudo yum -y install jq nodejs python36

# Install ecs cli for local testing
sudo curl -so /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli

# Setting CDK Version
export AWS_CDK_VERSION="1.41.0"

# Install aws-cdk
npm install -g --force aws-cdk@$AWS_CDK_VERSION

# For container insights and service autoscaling load generation
curl -C - -O http://download.joedog.org/siege/siege-4.0.5.tar.gz
tar -xvf siege-4.0.5.tar.gz
pushd siege-*
./configure
make all
sudo make install 
popd

# For the workshop, we will be using Python as our language for the aws-cdk
cd ~/environment
virtualenv .env
source .env/bin/activate

# Install cdk packages
pip install --upgrade aws-cdk.core==$AWS_CDK_VERSION \
aws-cdk.aws_ecs_patterns==$AWS_CDK_VERSION \
aws-cdk.aws_ec2==$AWS_CDK_VERSION \
aws-cdk.aws_ecs==$AWS_CDK_VERSION \
aws-cdk.aws_servicediscovery==$AWS_CDK_VERSION \
aws_cdk.aws_iam==$AWS_CDK_VERSION \
aws_cdk.aws_efs==$AWS_CDK_VERSION \
awscli \
awslogs

# Setting environment variables required to communicate with AWS API's via the cli tools
echo "export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)" >> ~/.bashrc
echo "export AWS_REGION=\$AWS_DEFAULT_REGION" >> ~/.bashrc
echo "export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)" >> ~/.bashrc
source ~/.bashrc
```
