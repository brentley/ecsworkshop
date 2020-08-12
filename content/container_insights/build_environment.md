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
git clone https://github.com/brentley/ecsdemo-nodejs
git clone https://github.com/brentley/ecsdemo-crystal
```

#### Build the platform

First, we need to build the environment for our frontend service to run. For more information on what we're building, you can review the code here: [Platform](../../microservices/platform/build_environment).

```bash
cd ~/environment/container-demo/cdk
cdk context --clear && cdk deploy --require-approval never
```

#### Deploy the microservices

Next, we will deploy a three-tier polyglot web app to our ECS cluster. For more information on what is being deployed, see the [microservices](../../microservices) section of the workshop.

```bash
cd ~/environment/ecsdemo-frontend/cdk
cdk context --clear && cdk deploy --require-approval never
cd ~/environment/ecsdemo-nodejs/cdk
cdk context --clear && cdk deploy --require-approval never
cd ~/environment/ecsdemo-crystal/cdk
cdk context --clear && cdk deploy --require-approval never
```

#### Next page

Once you've created the platform and deployed the services to the cluster, please move on to the next page.