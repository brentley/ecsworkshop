---
title: "Build the Platform"
date: 2018-02-14T10:31:01-06:00
draft: false
weight: 1
---

If breaking down a monolith into microservices is a good idea, then it stands to reason that
keeping the code that manages your app platform small and simple also makes sense.

In this workshop, we manage the infrastructure with this repository, and then each service
will be maintained in its own separate repository.

This repository will be used to build the base environment for the microservices to deploy to.

{{%expand "copilot-cli path" %}}
When we initialize our application, we will create our environment (which builds the platform resources). The platform resources that will be built and shared across our application are: VPC, Subnets, Security Groups, IAM Roles/Policies, ECS Cluster, Cloud Map Namespace (Service Discovery), Cloudwatch logs/metrics, and more!
{{% /expand %}}

{{%expand "cdk path" %}}
This repository will build the baseline platform for the microservices to deploy to. This includes VPC, ECS Cluster, and Cloud Map service discovery namespace. The AWS CDK will be the mechanism used to achieve this.

We will be continue using the AWS CDK to deploy our applications into this cluster.
{{% /expand %}}

{{%expand "ecs-cli path" %}}
This repository will use 2 CloudFormation Stacks that will build our cluster environment and ALB.

We will then use ecs-cli to deploy our applications into this cluster.
{{% /expand %}}

![mu-environment](/images/mu-topology-vpc.png)
