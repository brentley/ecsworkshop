---
title: Task Placement Validation
chapter: false
weight: 30
---

To run a ECS task on an ARM based EC2 instance, we need to provide three input parameters to the RunTask cli option. The RunTask command need ECS cluster, Task definition and CapacityProvider strategy. We generate the ARM_TASKDEF shell environment using the CloudFormation Output value. 

When we create the ARM based task definition using CloudFormation, we configured the task placement constraints. According to our placement constraint configuration, ECS scheduler will take the container instance CPU architecture and task will be placed only if CPU architecture is arm64 or else task will not be placed on Container instances with the ECS cluster. 

We can confirm the placement constraint configuration by describing the ARM based task definition and query the output for taskDefinition.placementConstraints value. This command also confirms that our ARM_TASKDEF value is set correctly.

```bash
ARM_TASKDEF=$(aws cloudformation describe-stacks --stack-name ecs-demo \
    --query 'Stacks[*].Outputs[?OutputKey==`Armtaskdef`]' --output text | awk '{print $NF}')
    
aws ecs describe-task-definition --task-definition $ARM_TASKDEF \
    --query 'taskDefinition.placementConstraints' 
```

The output should look like this:

```
[
    {
        "type": "memberOf",
        "expression": "attribute:ecs.cpu-architecture == arm64"
    }
]
```

Likewise, configured GPU_TASKDEF environment variable by querying the CloudFormation stack output for GPU task definition resource name.  We also created GPU base task definition and while creating this task definition, we configured the placement configuration to look for an instance-type equals to p2.xlarge. We confirm this by executing the describe task definition command against GPU_TASKDEF. 

```bash
$ GPU_TASKDEF=$(aws cloudformation describe-stacks --stack-name ecs-demo \
 --query 'Stacks[*].Outputs[?OutputKey==`Gputaskdef`]' --output text | awk '{print $NF}')
 
$ aws ecs describe-task-definition --task-definition $GPU_TASKDEF \
     --query 'taskDefinition.placementConstraints'
```

The output should look like this:

```
[
    {
        "type": "memberOf",
        "expression": "attribute:ecs.instance-type == p2.xlarge"
    }
]
```

Based on these constraints, when a user tries to launch an ECS Task (CreateService/RunTask), the ECS scheduler will look for the `constraints` field in the task definition. Based on the constraints, the task will be placed on the container instance within the ECS Cluster that matches the constraint.

If none of the available Container Instance(s) fulfill the requirement, the ECS scheduler will not be able to place the task.

#### 6.2 Validation under success scenario

Now it's time to get our tasks deployed! Run the following commands to get tasks deployed to our ECS cluster.

```bash
$ ARM_ECSCP=$(aws cloudformation describe-stacks --stack-name ecs-demo \
    --query 'Stacks[*].Outputs[?OutputKey==`ArmECSCapacityProvider`]' --output text | awk '{print $NF}')
$ aws ecs run-task --cluster $ECS_CLUSTER --task-definition $ARM_TASKDEF --capacity-provider-strategy "capacityProvider=${ARM_ECSCP}"
```

{{% notice note %}}
We can do the same for GPU enabled instances as well! 
Please note that GPU enabled instances are not free-tier eligible and costs may be incurred.
If you are running on your own, it's recommended to skip this section and just use for reference.
{{% /notice%}}

{{%expand "Expand here to see the GPU deployment code" %}}
```bash
$ GPU_ECSCP=$(aws cloudformation describe-stacks --stack-name ecs-demo \
    --query 'Stacks[*].Outputs[?OutputKey==`GpuECSCapacityProvider`]' --output text | awk '{print $NF}')
$ aws ecs run-task --cluster $ECS_CLUSTER --task-definition $GPU_TASKDEF --capacity-provider-strategy "capacityProvider=${GPU_ECSCP}"
```
{{% /expand %}}

You will get a JSON response indicating that a Task was submitted. Check for failure. If it is empty it means the task was submitted successfully. 
Also look for task lastStatus filed in JSON output and is in PROVISIONING stage. 

This will take a couple of minutes for cluster autoscaling to kick in. 
We start with zero instances in our cluster and let ECS handle the scaling of the EC2 instances based on demand.

Navigate to the ECS console and select the ecs-demo-ECSCluster-RANDOM, you will see that the Capacity provider ArmECSCapacityProvider and GpuECSCapacityProvider Current size increased to 1 for each. 

![schedule1](/images/ecs_advance_schedule1.png)

In the ECS Instance tab, you will see that now you have two EC2 instances (1 for each task). On ECS Instance tab, click on settings icon and select ecs.cpu-arhitecture and ecs-instance-type. Based on this value, you will see that the Capacity provider launched both GPU (instance-type=p2.xlarge) and ARM (cpu-architecture=arm64) instance types as required for the respective task definition constraints. 

![schedule2](/images/ecs_advance_schedule2.png)

That's it, we have successfully deployed two tasks onto our cluster based on specific placement constraints!

In the ECS console, navigate to tasks, check the boxes for the running tasks and select `Stop`.
After approximately 15 minutes, the cluster autoscaler will kill the EC2 instances as there are no tasks requiring them. 

Let's move on to the cleanup step to delete all of the resources.