---
title: "Embedded tab content"
disableToc: true
hidden: true
---

After reviewing the app and code, destroy the created stacks from the root of the cdk application project:

```bash
copilot app delete
```

This will remove the VPC, RDS Instance, Secrets Manager and ECS Fargate Cluster that were created along with any associated resources:

```text
Are you sure you want to delete application ecsworkshop? Yes
✔ Deleted service todo-app from environment test.
✔ Deleted resources of service todo-app from application ecsworkshop.
✔ Deleted service todo-app from application ecsworkshop.
✔ Deleted environment test from application ecsworkshop.
✔ Cleaned up deployment resources.
✔ Deleted application resources.
✔ Deleted application configuration.
✔ Deleted local .workspace file.
```
