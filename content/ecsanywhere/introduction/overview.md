+++
title = "Overview"
description = "Overview"
weight = 1
+++

ECS Anywhere is an extension of Amazon ECS that will allow customers to deploy native Amazon ECS tasks in any
environment. This will include the existing model on AWS managed infrastructure, as well as customer-managed
infrastructure. All this without compromising on the value of leveraging a fully AWS managed, easy to use, control plane that’s running in the cloud, and always up to date.

## Use-cases supported by ECS-Anywhere

ECS- Anywhere can solve the below use-cases:

* Manage legacy monolithic applications in customer data centers
* Run containers in the AWS Cloud and on-premises in a consistent manner
* Run applications on-premises for technical or compliance reasons
* Manage applications at edge locations consistently, efficiently, and reliably

## ECS-Anywhere Use-cases

* *(Modernization) Customers moving to containers and migrating their workloads to AWS.* Customers can now containerize their workloads on-premises first, make them portable, address on-premises dependencies, get familiar with AWS tools and get AWS-ready, followed by just updating the ECS services’ configuration from on-premises hardware to either Fargate or EC2.
* *(Hybrid) Customers who need to run containerized workloads on both AWS and on-premises.* Customers continue to run some workloads on-premises or other cloud environments for reasons such as data gravity, compliance, and latency requirements. Such customers need a single container orchestration platform for consistent tooling and deployment experience across all environments.
* *(Hybrid) Customers who want to continue to utilize their on-premises infrastructure until their investments have fully amortized.* Such customers are looking to use their on-premises infrastructure as base capacity while bursting into AWS during peaks or as their business grows. Over time, as they retire their on-premises hardware, they would continue to move the dial to use more compute on AWS until they have fully migrated.
* *(IoT) Customers wanting to run container workloads at multiple edge locations.* Such customers are looking to use ECS Anywhere to orchestrate containers at multiple edge locations. For example, these workloads could be gathering raw data from machines, or raw images from drones and processing them before sending to cloud.

## Containers using ECS-Anywhere

![ECS-Anywhere -Fit-in-Places](../images/Places-ECS.png)
