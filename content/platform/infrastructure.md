---
title: "Build the Platform"
date: 2018-02-14T10:31:01-06:00
draft: false
weight: 1
---

If breaking down a monolith into microservices is a good idea, then it stands to reason that
keeping the code that manages your app platform small and simple also makes sense.

In this workshop, we manage the infrastructure with this repository, and then each service
will be maintained in it's own separate repository.

This repository will generate CloudFormation Stacks that will build 2 independent environments
called **Acceptance** and **Production**.

![mu-environment](images/mu-topology-vpc.png)
