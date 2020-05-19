---
title: "Fargate Capacity Provider Setup"
disableToc: true
hidden: true
---
 
#### Enable Fargate capacity provider on existing cluster

First, we will update our ECS cluster to enable the fargate capacity provider. Because the cluster already exists, we will do it via the CLI as it presently can't be done via the console on existing clusters.

Using the AWS CLI, run the following command:

```bash
aws ecs put-cluster-capacity-providers \
--cluster container-demo \
--capacity-providers FARGATE FARGATE_SPOT \
--default-capacity-provider-strategy \
capacityProvider=FARGATE,weight=1,base=1 \
capacityProvider=FARGATE_SPOT,weight=2
```

#### Code Review

With this command, we're adding the Fargate and Fargate Spot capacity providers to our ECS Cluster. Let's break it down by each input:

 - `--cluster`: we're simply passing in our cluster name that we want to update the capacity provider strategy for.
 - `--capacity-providers`: this is where we pass in our capacity providers that we want enabled on the cluster. Since we do not use EC2 backed ECS tasks, we don't need to create a cluster capacity provider prior to this. With that said, there are only the two options when using Fargate.
 - `--default-capacity-provider-strategy`: this is setting a default strategy on the cluster; meaning, if a task or service gets deployed to the cluster without a strategy set, it will default to this. Let's break the base/weight down to get a better understanding.

The base value designates how many tasks, at a minimum, to run on the specified capacity provider. Only one capacity provider in a capacity provider strategy can have a base defined.

The weight value designates the relative percentage of the total number of launched tasks that should use the specified capacity provider. For example, if you have a strategy that contains two capacity providers, and both have a weight of 1, then when the base is satisfied, the tasks will be split evenly across the two capacity providers. Using that same logic, if you specify a weight of 1 for capacityProviderA and a weight of 4 for capacityProviderB, then for every one task that is run using capacityProviderA, four tasks would use capacityProviderB. 

So in the command we ran, we are saying that we want a minimum of 1 Fargate task as our base, and for every one task using Fargate strategy, four tasks will use Fargate Spot.

#### Deploy a service