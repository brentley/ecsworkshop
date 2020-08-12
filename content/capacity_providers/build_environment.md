---
title: "Build the Environments"
chapter: false
weight: 8
---

In the Cloud9 workspace, run the following commands:

- Create service linked roles for ECS:

```
aws iam get-role --role-name "AWSServiceRoleForECS" || aws iam create-service-linked-role --aws-service-name "ecs.amazonaws.com"
```

#### Clone the platform repository

Clone the service repos:

```bash
cd ~/environment
git clone https://github.com/brentley/container-demo
git clone https://github.com/adamjkeller/ecsdemo-capacityproviders
```

#### Build the platform

First, we need to build the environment for our frontend service to run. For more information on what we're building, you can review the code here: [Platform](../../microservices/platform/build_environment).

```bash
cd ~/environment/container-demo/cdk
cdk context --clear && cdk deploy --require-approval never
```


#### Next page

Once you've deployed the platform, please move on to the next page.