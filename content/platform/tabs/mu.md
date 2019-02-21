---
title: "Dry Run"
disableToc: true
hidden: true
---

Let's do a dry run and see what CloudFormation is generated!

Copy/Paste the following commands into your Cloud9 workspace:

```
cd ~/environment/ecsdemo-platform
mu -d env up acceptance
ls -la /tmp/mu-dryrun
```

The files are broken up into stacks, and include a _template_ for the CloudFormation and a _config_
for the parameters that will be templated.

To see how the VPC will be constructed, for example, take a look at the **template-mu-vpc-acceptance.yml** file:
```
less /tmp/mu-dryrun/template-${MU_NAMESPACE}-vpc-acceptance.yml
```

{{% notice tip %}}
This will dry-run Mu and generate CloudFormation so you can examine what will be built before actually building it.
{{% /notice %}}

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