---
title: "Build the Environments"
chapter: false
weight: 8
---

{{% notice note %}}
If you have gone through the "Deploying microservices to ECS" chapter and kept the resources up and running, you can skip this page and move to the next.
{{% /notice %}}


In the Cloud9 workspace, run the following commands:

- Ensure service linked roles exist for Load Balancers and ECS:

```
aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"

aws iam get-role --role-name "AWSServiceRoleForECS" || aws iam create-service-linked-role --aws-service-name "ecs.amazonaws.com"
```

#### Clone the platform repository

Clone the service repos:

```bash
cd ~/environment
git clone https://github.com/brentley/container-demo
```

#### Build the platform

First, we need to build the environment for our frontend service to run. Navigate to the microservices chapter and find the [Platform](../../microservices/platform) section and follow the steps to deploy via the cdk.

#### Next page

Once you've deployed the platform, please move on to the next page.