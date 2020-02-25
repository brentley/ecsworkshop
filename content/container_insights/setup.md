---
title: "Setup Container Insights"
chapter: false
weight: 10
---

#### Application setup
In this section we will setup Container insights for the sample application in this workshop [here](../../platform). If you haven't set it up yet, go ahead and setup the cluster on **ECS Fargate** and come back here.

#### Get the cluster name

Execute the following command. This will list the ECS clusters that are in your account and region

```
aws ecs list-clusters
```

#### Enable Container Insights 
Execute the following command to enable Container Insights on the cluster. This command will enable Service and Cluster level insights on your ECS cluster

```
aws ecs update-cluster-settings --cluster ${clustername}  --settings name=containerInsights,value=enabled --region ${AWS_REGION}
```

#### Enable Instance Level Insights
The following command will install Instance level insights on the ECS cluster.

```
aws cloudformation create-stack --stack-name CWAgentECS-$clustername-${AWS_REGION} --template-body "$(curl -Ls https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/ecs-task-definition-templates/deployment-mode/daemon-service/cwagent-ecs-instance-metric/cloudformation-quickstart/cwagent-ecs-instance-metric-cfn.json)" --parameters ParameterKey=ClusterName,ParameterValue=$clustername ParameterKey=CreateIAMRoles,ParameterValue=True --capabilities CAPABILITY_NAMED_IAM --region ${AWS_REGION}
```
#### Validate Container Insights is enabled on the ECS Cluster

Execute the following command

```
aws ecs describe-clusters --cluster ${clustername}
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
