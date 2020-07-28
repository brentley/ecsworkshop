---
title: "Stateful Workloads"
chapter: true
weight: 56
pre: '<i class="fa fa-film" aria-hidden="true"></i> '
---

# Stateful workloads on ECS Fargate

{{< youtube yfmBQ5MVFsc >}}

In this chapter, we will deploy a stateful workload on ECS Fargate with storage persisting on EFS. There are many reasons for wanting to deploy a stateful workload on containers, with some examples being: 

- Content Management Systems like Wordpress, or Drupal.
- Sharing static content for web servers
- Jenkins Master Nodes
- Machine learning
- Relational Databases for dev/test environments

While these are just a few examples, the need exists and we will dive into how to get your ECS Fargate containers to run with EFS! 

Let's get started...
