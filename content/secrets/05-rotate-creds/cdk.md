---
title: "Embedded tab content"
disableToc: true
hidden: true
---

We use the AWS CLI to force a new deployment.

```bash
#NOTE TO REVIEW - STILL ITERATING ON THIS.
aws ecs update-service --cluster ecsworkshop --service todo-app --force-new-deployment --desired-count 1
```