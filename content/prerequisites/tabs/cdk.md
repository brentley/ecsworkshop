---
title: "Embedded tab content"
disableToc: true
hidden: true
---

## Install and setup prerequisites

```
# Install prerequisite packages
sudo yum -y install jq nodejs python36

# Install aws-cdk
npm i -g aws-cdk

# For the workshop, we will be using Python as our language for the aws-cdk
pip install --upgrade aws-cdk.core

# This will dynamically grab the instance metadata which contains the region that this server is running in.
echo "export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)" >> ~/.bashrc
echo "export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)" >> ~/.bashrc
source ~/.bashrc

# Install ecs-cli for service status and interacting with the ecs cluster
sudo curl -so /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli
```

## Create a Python virtual environment

```bash
# Creating a virual environment where we can install python packages locally to ensure consistency when installing
cd ~/environment
virtualenv .env
source .env/bin/activate
```
