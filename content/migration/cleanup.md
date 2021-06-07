---
title: "Cleanup"
chapter: false
weight: 70
---

#### Cleanup

```bash
cd ~/environment/ec2_to_ecs_migration_workshop/app
copilot app delete --name userapi --yes
cd ~/environment/ec2_to_ecs_migration_workshop/build_ec2_environment
cdk destroy -f
```