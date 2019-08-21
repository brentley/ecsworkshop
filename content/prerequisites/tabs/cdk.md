---
title: "Embedded tab content"
disableToc: true
hidden: true
---

## Choose your region, and store it in this environment variable

```
# Install jq for parsing json
sudo yum -y install jq

# This will dynamically grab the instance metadata which contains the region that this server is running in.
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

# Export the AWS_REGION variable to ensure that it is set on startup of a new terminal
echo "export AWS_REGION=${AWS_REGION}" >> ~/.bash_profile
```

## Install ecs-cli for service status and interacting with the ecs cluster
```
sudo curl -so /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli
```

## Setup aws-cdk

Recommendation is to use the cdk docker container as it contains all of the libraries and doesn't require any installation of npm or python modules.

```bash
CDK_VERSION=v0.36.0

function cdk { docker run -v $(pwd):/cdk -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -it adam9098/aws-cdk:${CDK_VERSION} $@; }
```