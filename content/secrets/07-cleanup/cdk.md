---
title: "Embedded tab content"
disableToc: true
hidden: true
---


After reviewing the app and code, destroy the created stacks from the root of the cdk application project:

```bash
cdk destroy --all -f
```

This will remove the VPC, RDS Cluster, Secrets Manager and ECS Fargate Cluster that were created along with any associated resources.
