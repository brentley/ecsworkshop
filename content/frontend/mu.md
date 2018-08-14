+++
title = "Frontend Service"
chapter = false
weight = 1
+++

Again, we can take advantage of opinionated tooling to deploy our service using best practices.

When a service team wants to build a new service, they can include their own
[mu.yml](https://github.com/brentley/ecsdemo-frontend/blob/master/mu.yml) and inherit
best practices such as blue/green deploys, healthchecks, and autoscaling for their service.

```
---
service:
  desiredCount: 3
  maxSize: 6
  port: 3000
  pathPatterns:
  - /*
  networkMode: awsvpc
  environment:
    CRYSTAL_URL: "http://ecsdemo-crystal/crystal"
    NODEJS_URL: "http://ecsdemo-nodejs/"
```

In this file, we define the service and how it should run. We want a minimum of 3 containers
of our service running, for redundancy.  These will automatically be spread across our 3
availability zones.

Autoscaling will be configured with a maximum of 6 containers.

The containers listen on port 3000, and native service discovery is configured to
register and provide IP and port resolution for any running containers.

We're using _awsvpc_ networking mode, so each task will get it's own ENI with IP address.

When each container is launched, it will have two custom environment variables set
so the application can use native service discovery to locate the backend services.
