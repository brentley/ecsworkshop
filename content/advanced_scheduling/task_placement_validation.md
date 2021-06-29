---
title: Task Placement Validation
chapter: false
weight: 40
---


#### 6.1 List of instances.

List container instances before you submit tasks to make sure you don’t have any container instances. And after you submit tasks, the capacity provider should launch an EC2 instance and register it to an ECS cluster to run the task


```bash
$ aws ecs list-container-instances --cluster $ECS_CLUSTER --output table
+----------------------+
|ListContainerInstances|
+----------------------+
```

#### 6.2 Validation under success scenario

By default, when you place task using RunTask , the ECS service scheduler will select the default ECS Capacity Provider with weight 1. If you want to submit a job to a desired Capacity Provider, you need to pass it as an input parameter with the RunTask cli option. We have also configured a constraint, so the ECS cluster will check for constraints before it places the task on desired instance. 


```bash
$ GPU_ECSCP=$(aws cloudformation describe-stacks --stack-name ecs-demo \
    --query 'Stacks[*].Outputs[?OutputKey==`GpuECSCapacityProvider`]' --output text | awk '{print $NF}')
$ aws ecs run-task --cluster $ECS_CLUSTER --task-definition $GPU_TASKDEF --capacity-provider-strategy "capacityProvider=${GPU_ECSCP}"
```



```bash
$ ARM_ECSCP=$(aws cloudformation describe-stacks --stack-name ecs-demo \
    --query 'Stacks[*].Outputs[?OutputKey==`ArmECSCapacityProvider`]' --output text | awk '{print $NF}')
$ aws ecs run-task --cluster $ECS_CLUSTER --task-definition $ARM_TASKDEF --capacity-provider-strategy "capacityProvider=${ARM_ECSCP}"
```

You will get a JSON response indicating that a Task was submitted. Check for failure. If it is empty it means the task was submitted successfully.  Also look for task lastStatus filed in JSON output and is in PROVISIONING stage. 

Wait for couple of minutes until the cluster autoscaling utilization metric of both the Capacity provider is triggered and,  ARM and GPU based AutoScaling is scaled out.  

If you go back to the ECS console and select the ecs-demo-ECSCluster-RANDOM, you will see that the Capacity provider ArmECSCapacityProvider and GpuECSCapacityProvider Current size increased to 1 for each. 

![schedule1](/images/ecs_advance_schedule1.png)If you go to the ECS Instance tab, you will see that now you have two EC2 instances 1 for each task. On ECS Instance tab, click on settings icon and select ecs.cpu-arhitecture and ecs-instance-type. Based on this value, you will see that the Capacity provider launched both GPU (instance-type=p2.xlarge) and ARM (cpu-architecture=arm64) instance types as required for the respective task definition constraints. 

![schedule2](/images/ecs_advance_schedule2.png)
#### 6.3 Capacity provider will terminate the instances after 15 minutes after tasks are stopped successfully. 

```bash
$ aws ecs list-container-instances --cluster $ECS_CLUSTER --output table
+----------------------+
|ListContainerInstances|
+----------------------+
```

#### 6.4 Validation under failure scenario 

For this ECS cluster, the default Capacity Provider is a GPU based capacity provider. If you execute run-task cli, with $GPU_TASKDEF without ‘—capacity-provider-strategy’ option, the ECS scheduler will take the default capacity provider and will run the job. As all of the constraints are fulfilled, the task will be placed on a container instance and it will complete successfully. 


```bash
$ aws ecs run-task --cluster $ECS_CLUSTER --task-definition $GPU_TASKDEF 
```

But if you try to run $ARM_TASKDEF without ‘—capacity-provider-strategy ‘ flag, it will get stuck in the PROVISIONING stage. The ECS scheduler will select GPU capacity provider and as $ARM_TASKDEF constraints are not fulfilled, the task will be stuck in the pending state and it will FAIL after 30 minutes. 


```bash
$ aws ecs run-task --cluster $ECS_CLUSTER --task-definition $ARM_TASKDEF 
```

Wait for a couple of minutes until the cluster autoscaling utilization metric is triggered. Only one instance is launched for GPU based capacity provider as it is the default capacity provider. 

![schedule3](/images/ecs_advance_schedule3.png)
If you go to the task tab, you will see that, we have only one task in the RUNNING state and another in PROVISIONING. Looking at the task definition, you will see that only the gpu based task is RUNNING and the ARM64 based task is stuck in the PROVISIONING state. 

GPU based task → constraints (instance-type=p2.xlarge) → default capacity provider (GPU) → As both conditions match, the task will be placed successfully. 

ARM base task → constaints(cpu-architecture=arm64) → default capacity provide(GPU) → as architecture of GPU is x86_64 and does not match to arm64, the ECS scheduler will trigger ECS capacity provider to launch the GPU instance type. 

#### 6.5 Capacity provider will terminate the instances after 15 minutes after tasks are stopped successfully. 

```bash
$ aws ecs list-container-instances --cluster $ECS_CLUSTER --output table
+----------------------+
|ListContainerInstances|
+----------------------+
```
