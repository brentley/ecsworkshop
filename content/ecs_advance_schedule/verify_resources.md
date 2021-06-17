---
title: Verify the created resources
chapter: false
weight: 30
---

To run a ECS task on an ARM based EC2 instance, we need to provide three input parameters to the RunTask cli option. The RunTask command need ECS cluster, Task definition and CapacityProvider strategy. We generate the ARM_TASKDEF shell environment using the CloudFormation Output value. 

When we create the ARM based task definition using CloudFormation, we configured the task placement constraints. According to our placement constraint configuration, ECS scheduler will take the container instance CPU architecture and task will be placed only if CPU architecture is arm64 or else task will not be placed on Container instances with the ECS cluster. 

We can confirm the placement constraint configuration by describing the ARM based task definition and query the output for taskDefinition.placementConstraints value. This command also confirms that our ARM_TASKDEF value is set correctly.

```bash
$ ARM_TASKDEF=$(aws cloudformation describe-stacks --stack-name ecs-demo \
    --query 'Stacks[*].Outputs[?OutputKey==`Armtaskdef`]' --output text | awk '{print $NF}')
    
$ aws ecs describe-task-definition --task-definition $ARM_TASKDEF \
    --query 'taskDefinition.placementConstraints' 
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
[
    {
        "type": "memberOf",
        "expression": "attribute:ecs.instance-type == p2.xlarge"
    }
]
```

Based on these constraints, when a user tries to launch an ECS Task (CreateService/RunTask), the ECS scheduler will look for the `constraints` field in the task definition. Based on the constraints, the task will be placed on the Container Instance within the ECS Cluster or whichever fulfills the requirement.

If none of the available Container Instance(s) fulfill the requirement, the ECS scheduler will not be able to place the task.

You can configure ECS Constraints in ECS Task Definition using both [built-in](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes)and [custom attributes](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#add-attribute).