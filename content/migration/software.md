---
title: "Install and Configure Tools"
chapter: false
weight: 10
---

In the Cloud9 workspace, run the following commands:

## Install and setup prerequisites

```
# Pull down the git repo
cd ~/environment
git clone https://github.com/adamjkeller/ecsdemo-migration-to-ecs.git

# Install prerequisite packages
sudo yum -y install jq nodejs python36

# Install aws-cdk
npm install -g --force aws-cdk@1.106.1

# Setup virtual environment
cd ecsdemo-migration-to-ecs && virtual env .env && source .env/bin/activate
pip3 install -r requirements.txt

# Setting environment variables required to communicate with AWS API's via the cli tools
echo "export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)" >> ~/.bashrc
echo "export AWS_REGION=\$AWS_DEFAULT_REGION" >> ~/.bashrc
echo "export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)" >> ~/.bashrc
source ~/.bashrc

#Install AWS Copilot cli
curl -Lo copilot https://github.com/aws/copilot-cli/releases/latest/download/copilot-linux && \
chmod +x copilot && \
sudo mv copilot /usr/local/bin/copilot &&\
copilot --help

```
