+++
title = "Environments"
chapter = false
weight = 20
draft = true
+++

Let's clean up the environments:

```
cd ~/environment/ecsdemo-platform
mu env term acceptance
mu env term production

```
{{% notice note %}}
This terminates all running services and resources down to the VPCs
{{% /notice %}}
