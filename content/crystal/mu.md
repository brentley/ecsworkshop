+++
title = "Crystal Backend Service"
chapter = false
weight = 1
+++

For this backend api service, we want to use our backend ALB so that this API
is only reachable from inside our VPC. Check out
[mu.yml](https://github.com/brentley/ecsdemo-crystal/blob/master/mu.yml) and notice
how we've overridden two of the default CloudFormation parameters to point to
the backend ALB:

```
---
service:
  desiredCount: 3
  maxSize: 6
  port: 3000
  priority: 2
  pathPatterns:
  - /crystal
  networkMode: awsvpc
parameters:
  'mu-service-ecsdemo-crystal-acceptance':
    ElbHttpListenerArn:
        mu-loadbalancer-acceptance-BackendLBHttpListenerArn
  'mu-service-ecsdemo-crystal-production':
    ElbHttpListenerArn:
        mu-loadbalancer-production-BackendLBHttpListenerArn
```

{{% notice note %}}
Our pathPatterns for route matching is set specifically to **/crystal**
and we've set a high priority.  This will carve off any traffic to this ALB
that starts with **/crystal/** and route that traffic to this service, rather than
the default Node.js service.
{{% /notice %}}
