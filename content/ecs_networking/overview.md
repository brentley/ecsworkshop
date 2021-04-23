---
title: "Overview"
chapter: false
weight: 10
---

## Network modes

If using the EC2 launch type, the allowable network mode depends on the underlying EC2 instance's operating system. If Linux, awsvpc, bridge, host and none mode can be used. If Windows, only the NAT mode is allowed.

If using the Fargate launch type, the 'awsvpc' is the only network mode supported.

[Amazon ECS task networking](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html)

The networking behavior of Amazon ECS tasks hosted on Amazon EC2 instances is dependent on the network mode defined in the task definition. The following are the available network modes.
Amazon ECS recommends using the awsvpc network mode unless you have a specific need to use a different network mode.

- awsvpc — The task is allocated its own elastic network interface (ENI) and a primary private IPv4 address. This gives the task the same networking properties as Amazon EC2 instances.

- bridge — The task utilizes [Docker's built-in virtual network](https://docs.docker.com/network/bridge/) which runs inside each Amazon EC2 instance hosting the task.

- host — The task [bypasses Docker's built-in virtual network](https://docs.docker.com/network/host/) and maps container ports directly to the ENI of the Amazon EC2 instance hosting the task. As a result, you can't run multiple instantiations of the same task on a single Amazon EC2 instance when port mappings are used.

- none — The task has no external network connectivity.

For more information about Docker networking, see [Networking overview](https://docs.docker.com/network/)

- NAT - Docker for Windows uses a different network mode (known as [NAT](https://docs.microsoft.com/en-us/virtualization/windowscontainers/container-networking/network-drivers-topologies)) than Docker for Linux.

Note: If you create an ECS task defintion in the AWS console and choose EC2 launch type
there is a "Network Mode: \<default\> option. ECS will start your container using Docker's default networking mode, which is Bridge on Linux and NAT on Windows. \<default\> (NAT) is the only supported mode on Windows.

[Fargate task networking](https://docs.aws.amazon.com/AmazonECS/latest/userguide/fargate-task-networking.html)

By default, every Amazon ECS task on Fargate is provided an elastic network interface (ENI) with a primary private IP address.