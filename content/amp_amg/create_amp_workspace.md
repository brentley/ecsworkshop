---
title: "Create AMP workspace"
draft: false
weight: 7
---

## Create a new AMP workspace

Go to the [AMP console](https://console.aws.amazon.com/prometheus/home) and type-in a name for the AMP workspace and click on `Create`

![Create AMP workspace](/images/amp1.png)

Alternatively, you can also use AWS CLI to create the workspace using the following command:

```
aws amp create-workspace --alias ecs-workshop --region $AWS_REGION
```

The AMP workspace should be created in just a few seconds. Once created, you will be able to see the workspace as shown below:

![AMP workspace created](/images/amp2.png)
