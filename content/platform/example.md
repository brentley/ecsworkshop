+++
title = "Example"
chapter = false
weight = 4
+++

To build both the **Acceptance** and **Production** platforms, the only code we maintain ourselves
is found in [mu.yml](https://github.com/brentley/ecsdemo-platform/blob/master/mu.yml)

```
---
environments:
  - name: acceptance
    provider: ecs-fargate
  - name: production
    provider: ecs-fargate
service:
    acceptance:
      disabled: true
    production:
      disabled: true
extensions:
  - url: backend-service
  ```
In this file, we define that we want two environments, each using **Amazon ECS** and **AWS Fargate for ECS**.
We disable any service deploys, since this repo is only used to build and maintain infrastructure.

We also include the extension [backend-service](https://github.com/brentley/ecsdemo-platform/blob/master/backend-service/elb.yml).
This is custom CloudFormation used to build a private DNS zone **internal.service** and private
ALB for handling our backend api traffic.

Because we're using Mu and it's built-in best practice defaults, the amount of code we have to maintain
remains simple.
