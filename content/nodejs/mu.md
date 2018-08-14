+++
title = "Node.js Backend Service"
chapter = false
weight = 1
+++

For this backend api service, we want to use our native service discovery so that this API
is only reachable from inside our VPC. Check out
[mu.yml](https://github.com/brentley/ecsdemo-frontend/blob/master/mu.yml) and notice
how we've set the environment variables to point to the native service discovery name for this service:

```
---
service:
  desiredCount: 3
  maxSize: 6
  port: 3000
```

{{% notice note %}}
We are using native service discovery to address our running containers. Any request going to
**http://ecsdemo-nodejs/** will cause a dns SRV lookup to our internal route53 zone where
containers register when they start.  This is handled in the frontend application. [Check this code block
in the frontend application](https://github.com/brentley/ecsdemo-frontend/blob/master/app/controllers/application_controller.rb#L63)
{{% /notice %}}
