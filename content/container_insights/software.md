---
title: "Install and Configure Tools"
chapter: false
weight: 5
---

In the Cloud9 workspace, run the following commands:

## Install and setup prerequisites

```
# Install prerequisite packages
sudo yum -y install jq gettext
```
jq is a tool that can be used to extract and transform data held in JSON files.

The gettext package includes the envsubst utility, which can be used to substitute the values of environment variables into an input stream.

We will use these tools, along with the Linux utiltity sed, to insert or replace attribute values in various files throughout the workshop. This avoids the need for manual text editing wherever possible.

```
# Setting environment variables required to communicate with AWS API's via the cli tools
echo "export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)" >> ~/.bashrc
echo "export AWS_REGION=\$AWS_DEFAULT_REGION" >> ~/.bashrc
echo "export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)" >> ~/.bashrc
source ~/.bashrc
```
