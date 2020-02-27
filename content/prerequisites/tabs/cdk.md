---
title: "Embedded tab content"
disableToc: true
hidden: true
---

## Install and setup prerequisites

```
# Install prerequisite packages
sudo yum -y install jq nodejs python36

# Setting CDK Version
export AWS_CDK_VERSION="1.25.0"

# Install aws-cdk
npm install -g --no-bin-links aws-cdk@$AWS_CDK_VERSION

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
awslogs

# Setting environment variables required to communicate with AWS API's via the cli tools
echo "export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)" >> ~/.bashrc
echo "export AWS_REGION=$AWS_DEFAULT_REGION" >> ~/.bashrc
echo "export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)" >> ~/.bashrc
source ~/.bashrc
```