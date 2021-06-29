---
title: Default Capacity Provider for ECS Cluster
chapter: false
weight: 50
---

Based on the Capacity Provider Weight value, ECS Cluster will take it as the default Capacity Provider for the ECS cluster. Use the following command to verify the weight:

```bash
$ ECS_CLUSTER=$(aws cloudformation describe-stacks --stack-name ecs-demo \
    --query 'Stacks[*].Outputs[?OutputKey==`ecscluster`]' --output text | awk '{print $NF}')

$ aws ecs describe-clusters --cluster $ECS_CLUSTER --query 'clusters[].defaultCapacityProviderStrategy' --output table----------------------------------------------
|              DescribeClusters              |
+------+--------------------------+----------+
| base |    capacityProvider      | weight   |
+------+--------------------------+----------+
|  0   |  ArmECSCapacityProvider  |  0       |
|  0   |  GpuECSCapacityProvider  |  1       |
+------+--------------------------+----------+
```

The *base* value designates how many tasks, at a minimum, to run on the specified capacity provider. Only one capacity provider in a capacity provider strategy can have a base defined.

The *weight* value designates the relative percentage of the total number of launched tasks that should use the specified capacity provider. For example, if you have a strategy that contains two capacity providers, and both have a weight of `1`, then when the base is satisfied, the tasks will be split evenly across the two capacity providers. Using that same logic, if you specify a weight of `1` for *capacityProviderA* and a weight of `4` for *capacityProviderB*, then for every one task that is run using *capacityProviderA*, four tasks would use *capacityProviderB*.
