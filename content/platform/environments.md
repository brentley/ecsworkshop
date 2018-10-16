+++
title = "Acceptance and Production"
chapter = false
weight = 7
+++

Let's bring up the Acceptance and Production environments!

Copy/Paste the following commands into your Cloud9 workspace:

```zsh
cd ~/environment/ecsdemo-platform
mu env up -A
```
Watch what is being built in [CloudFormation](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks)
{{% notice tip %}}
This will take 10 minutes
{{% /notice %}}
