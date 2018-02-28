+++
title = "Node.js Backend Service"
chapter = false
pre = "<i class='fa fa-info-circle' aria-hidden='true'></i> "
weight = 1
+++

For this backend api service, we want to use our backend ALB so that this API
is only reachable from inside our VPC. Check out
[mu.yml](https://github.com/brentley/ecsdemo-nodejs/blob/master/mu.yml) and notice
how we've overridden a couple of the default CloudFormation parameters to point to
the backend ALB:

```
---
service:
  desiredCount: 3
  maxSize: 6
  port: 3000
  priority: 50
  pathPatterns:
  - /*
  networkMode: awsvpc
parameters:
  'mu-service-ecsdemo-nodejs-acceptance':
    ElbHttpListenerArn:
        mu-loadbalancer-acceptance-BackendLBHttpListenerArn
  'mu-service-ecsdemo-nodejs-production':
    ElbHttpListenerArn:
        mu-loadbalancer-production-BackendLBHttpListenerArn
```

{{% notice note %}}
Our pathPatterns for route matching is going to match everything
(like in our frontend ALB settings), but we've set a very low priority.  This allows us
to continue adding higher priority backend APIs, carving off specific routes. This API will
be our default _catch-all_ api.
{{% /notice %}}
