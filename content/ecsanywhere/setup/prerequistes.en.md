+++
title = "Pre-requistes"
description = "Pre-requiste steps for setting up and running workloads in ECS-A"
weight = 1
+++

Before we get started lets checkout the helper scripts used in this workshop.

{{% notice note %}}
Git client needs to be installed in the local machine, before running the following command. Follow this [link](https://git-scm.com/downloads) to download and install git client
{{% /notice %}}

```bash
mkdir aws-ecs-anywhere-workshop-samples && cd aws-ecs-anywhere-workshop-samples
git clone https://github.com/aws-samples/aws-ecs-anywhere-workshop-samples .
```

Setup the environment variables required to build ECS-anywhere cluster and run workloads using the newly created cluster.

{{% notice note %}}
Change the name of the `CLUSTER_NAME` and `SERVICE_NAME` if desired, for running multiple tests.
{{% /notice %}}

```bash
export AWS_DEFAULT_REGION=us-east-1
export ROLE_NAME=ecsMithrilRole
export CLUSTER_NAME=test-ecs-anywhere
export SERVICE_NAME=test-ecs-anywhere-svc
```

> Note: Change the value of `AWS_DEFAULT_REGION` to match the default AWS region.