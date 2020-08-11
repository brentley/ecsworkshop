+++
title = "Build the Environments"
chapter = false
weight = 6
+++

In the Cloud9 workspace, run the following commands:

- Ensure service linked roles exist for Load Balancers and ECS:

```
aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"

aws iam get-role --role-name "AWSServiceRoleForECS" || aws iam create-service-linked-role --aws-service-name "ecs.amazonaws.com"
```

#### Application setup

In this section we will setup Container insights. In order to get started, we need to deploy the environment as well as a frontend service in ECS. 
If you deployed the microservices in the chapter prior, you can skip this step and move on to the next page.

#### Clone the repos

Clone the service repos:

```bash
cd ~/environment
git clone https://github.com/brentley/container-demo
git clone https://github.com/brentley/ecsdemo-frontend
```

#### Build the platform

First, we need to build the environment for our frontend service to run. Navigate to the microservices chapter and find the [Platform](../../microservices/platform) section and follow the steps to deploy via the cdk.

#### Deploy the frontend load balanced microservice

Next, we need to deploy the frontend microservice to our ECS Cluster. Navigate to the microservices chapter and follow the cdk steps for the [Frontend Rails App](../../microservices/frontend).

#### Next page

Once you've created the platform and deployed the frontend service, please move on to the next page.