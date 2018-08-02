+++
title = "Environments"
chapter = false
weight = 2
+++

Let's clean up the environments:

```
cd ~/environment/ecsdemo-platform
mu -I env term acceptance
mu -I env term production
mu env term acceptance
mu env term production

```
{{% notice note %}}
This terminates all running services and resources down to the VPCs
{{% /notice %}}
