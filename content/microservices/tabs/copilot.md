---
title: "Embedded tab content"
disableToc: true
hidden: true
---

### Install and setup prerequisites

```
# Install prerequisites 
sudo yum install -y jq

pip install --user --upgrade awscli

# Install copilot-cli
brew install aws/tap/copilot-cli

# Setting environment variables required to communicate with AWS API's via the cli tools
echo "export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)" >> ~/.bashrc
source ~/.bashrc

mkdir -p ~/.aws

cat << EOF > ~/.aws/config
[default]
region = ${AWS_DEFAULT_REGION}
output = json
role_arn = $(aws iam get-role --role-name ecsworkshop-admin | jq -r .Role.Arn)
credential_source = Ec2InstanceMetadata
EOF

```
