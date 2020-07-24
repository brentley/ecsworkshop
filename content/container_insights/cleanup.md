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

{{% notice tip%}}
There is a lot more to learn about our Observability features using Amazon CloudWatch and AWS X-Ray. Take a look at our [One Observability Workshop](https://observability.workshop.aws)
{{% /notice%}}

