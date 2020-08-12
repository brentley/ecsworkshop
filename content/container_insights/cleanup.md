---
title: "Clean up resources"
chapter: false
weight: 50
---

As you can see it’s fairly easy to get CloudWatch Container Insights to work, and set alarms for CPU and other metrics. With CloudWatch Container Insights we remove the need to manage and update your own monitoring infrastructure and allow you to use native AWS solutions that you don’t have to manage the platform for.

#### Disable Container Insights
To disable container insights for the ECS cluster execute following command.

```
aws ecs update-cluster-settings --cluster ${clustername} --settings name=containerInsights,value=disabled --region ${AWS_REGION}
```
Your output should look similar to this one below.

```
{
    "cluster": {
        "status": "ACTIVE", 
        "statistics": [], 
        "tags": [], 
        "clusterName": "container-demo-ECSCluster-1E4H2VVHM9D2R", 
        "settings": [
            {
                "name": "containerInsights", 
                "value": "disabled"
            }
        ], 
        "registeredContainerInstancesCount": 0, 
        "pendingTasksCount": 0, 
        "runningTasksCount": 0, 
        "activeServicesCount": 0, 
        "clusterArn": "arn:aws:ecs:us-west-2:123456789:cluster/container-demo-ECSCluster-1E4H2VVHM9D2R"
    }
}
```
Go to [CloudFormation] (https://console.aws.amazon.com/cloudformation/home) and delete the stack that got created to enable Instance level insights.

![Cluster Dashboard](/images/ContainerInsights29.png)


Destroy the frontend service stack and the platform stack:

```bash
cd ~/environment/ecsdemo-frontend/cdk
cdk destroy -f
cd ~/environment/ecsdemo-nodejs/cdk
cdk destroy -f
cd ~/environment/ecsdemo-crystal/cdk
cdk destroy -f
cd ~/environment/container-demo/cdk
cdk destroy -f

python -c "import boto3
c = boto3.client('logs')
services = ['ecsworkshop-frontend', 'ecsworkshop-nodejs', 'ecsworkshop-crystal']
for service in services:
    frontend_logs = c.describe_log_groups(logGroupNamePrefix=service)
    print([c.delete_log_group(logGroupName=x['logGroupName']) for x in frontend_logs['logGroups']])"

```

{{% notice tip%}}
There is a lot more to learn about our Observability features using Amazon CloudWatch and AWS X-Ray. Take a look at our [One Observability Workshop](https://observability.workshop.aws)
{{% /notice%}}

