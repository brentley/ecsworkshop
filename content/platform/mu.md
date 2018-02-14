+++
title = "Opinionated Tooling"
chapter = false
weight = 2
+++

Opinionated tooling is designed to guide you down a path that is considered a "best practice".
Additionally, since "best practice" is the default, the amount of code we maintain is
dramatically reduced. Rather than writing hundreds of lines of CloudFormation ourselves, we
can start with a smart set of defaults, and just fill in a few blanks, and customize only the parts
that we want changed.

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
In this file, we define that we want two environments, each using **ECS Fargate**.
We disable any service deploys, since this repo is only used to build and maintain infrastructure.

We also include the extension **backend-service**.  This is custom CloudFormation used to build
a private DNS zone **internal.service** and private ALB for handling our backend api traffic.

Because we're using Mu and it's built-in best practice defaults, the amount of code we have to maintain
remains simple.
