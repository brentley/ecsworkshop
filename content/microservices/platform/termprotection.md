+++
title = "Set Termination Protection"
chapter = false
weight = 80
draft = true
+++

CloudFormation is executing most changes using an assumed role created by Mu.
We want to ensure we don't accidentally delete this role, breaking our ability
to update the CloudFormation stacks. We will set termination protection on
the CloudFormation stack that created this role:

Copy/Paste the following commands into your Cloud9 workspace:
```bash
aws cloudformation update-termination-protection --enable-termination-protection --stack-name "$MU_NAMESPACE-iam-common"
```
