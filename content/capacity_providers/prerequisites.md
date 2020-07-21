+++
title = "Deploy Platform"
chapter = false
weight = 2
+++

#### Deploy platform

If you are coming to this section from the ecs cli chapters, we will build out the platform, just as we did in the previous chapters.
If you are coming from the cdk chapters, please disregard and continue to the next page.


In the below commands, we will clone the platform repo, and deploy the platform. If you are interested in a walkthrough of what is being built, please check the [platform](https://ecsworkshop.com/platform/build_environment/) section of this workshop.
```
cd ~/environment
git clone https://github.com/brentley/container-demo
cd ~/environment/container-demo/cdk
cdk deploy --require-approval never
```