+++
title = "Build the Environment"
chapter = false
weight = 6
+++

In the Cloud9 workspace, run the following commands:


#### Clone the repos

Clone the service repos:

```bash
cd ~/environment
git clone https://github.com/brentley/container-demo
```

#### Build the platform

First, we need to build the environment for our application service to run. For more information on what we're building, you can review the code here: [Platform](../../microservices/platform/build_environment).

```bash
cd ~/environment/container-demo/cdk
cdk context --clear && cdk deploy --require-approval never
```

#### Next page

Once you've created the platform, please move on to the next page.