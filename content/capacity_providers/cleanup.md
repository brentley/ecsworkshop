+++
title = "Clean up"
chapter = false
weight = 60
+++

#### Delete the ecs applications and platform

```bash
cd ~/environment/ecsdemo-capacityproviders/ec2
cdk destroy -f
cd ~/environment/ecsdemo-capacityproviders/fargate
cdk destroy -f
cd ~/environment/container-demo/cdk
cdk destroy -f
```

```bash
python -c "import boto3
c = boto3.client('logs')
services = ['ecsworkshop-capacityproviders-fargate', 'ecsworkshop-capacityproviders-ec2']
for service in services:
    frontend_logs = c.describe_log_groups(logGroupNamePrefix=service)
    print([c.delete_log_group(logGroupName=x['logGroupName']) for x in frontend_logs['logGroups']])"
```