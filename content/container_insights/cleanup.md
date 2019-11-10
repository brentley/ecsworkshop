---
title: "Clean up resources"
chapter: false
weight: 5
---

#### Disable Container Insights
To disable container insights for the ECS cluster execute following command after replacing **cluster_name_or_arn** with your cluster name.

```
aws ecs update-cluster-settings --cluster <cluster_name_or_arn>  --settings name=containerInsights,value=disabled --region us-west-2
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

#### Clean up ECS cluster
Clean up the ECS cluster by following the procedures [here](../../cleanup)