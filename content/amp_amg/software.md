---
title: "Install and Configure Tools"
chapter: false
weight: 5
---
If you haven’t setup Cloud9 workspace, please go to the [Create a Workspace](https://ecsworkshop.com/start_the_workshop/workspace/) section and setup it.

In the Cloud9 workspace, run the following commands:

## Install and setup prerequisites

```
#  Clone application repository
cd ~/environment
git clone https://github.com/aws-samples/ecsdemo-amp.git

# Create Python virtual environment and install required CDK dependencies
cd ~/environment/ecsdemo-amp/cdk
virtualenv .env
source .env/bin/activate
pip install -r requirements.txt

# Bootstrap CDK toolkit stack
cdk bootstrap aws://$AWS_ACCOUNT_ID/$AWS_DEFAULT_REGION

```
