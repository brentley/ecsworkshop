---
title: "Setup Container Insights"
chapter: false
weight: 1
---

#### Application setup
In this section we will setup Container insights for the sample application in this workshop [here](../../platform). If you haven't set it up yet, go ahead and setup the cluster on **ECS Fargate** and come back here.

#### Get the cluster name

Execute the following command. This will list the ECS clusters that are in your account and region

```
aws ecs list-clusters
```

Copy the cluster name or the ARN of the cluster and replace **cluster_name_or_arn** with it. Then execute the following command to enable Container Insights on the cluster. 

```
aws ecs update-cluster-settings --cluster cluster_name_or_arn  --settings name=containerInsights,value=enabled --region us-west-2
```
#### Validate Container Insights is enabled on the ECS Cluster

Execute the following command

```
aws ecs describe-clusters --cluster **cluster_name_or_arn**
```
Your output should be similar to the one below. You should see Container Insights being enabled under **settings** section in the JSON.

```
{
    "clusters": [
        {
            "status": "ACTIVE", 
            "statistics": [], 
            "tags": [], 
            "clusterName": "container-demo-ECSCluster-1E4H2VVHM9D2R", 
            "settings": [
                {
                    "name": "containerInsights", 
                    "value": "enabled"
                }
            ], 
            "registeredContainerInstancesCount": 0, 
            "pendingTasksCount": 0, 
            "runningTasksCount": 9, 
            "activeServicesCount": 3, 
            "clusterArn": "arn:aws:ecs:us-west-2:1234567899:cluster/container-demo-ECSCluster-1E4H2VVHM9D2R"
        }
    ], 
    "failures": []
}
```