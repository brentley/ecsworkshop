---
title: "Application Cleanup"
chapter: false
weight: 54
---

After you have reviewed the app and code, destroy the created stacks from the root of the cdk application project:

```
cdk destroy --all -f
```

This will remove the VPC, RDS Instance, and ECS Cluster that were created along with any associated resources. 


