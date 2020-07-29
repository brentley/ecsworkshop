---
title: "Embedded tab content"
disableToc: true
hidden: true
---

- First install the ECS cli (plus some other text utilities):

```
sudo curl -so /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli

sudo yum -y install jq gettext

# For container insights and service autoscaling load generation
curl -C - -O http://download.joedog.org/siege/siege-4.0.5.tar.gz
tar -xvf siege-4.0.5.tar.gz
pushd siege-*
./configure
make all
sudo make install 
popd

```

- Next configure the AWS cli with our current region as default:

```
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
echo "export AWS_REGION=${AWS_REGION}" >> ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region
```

