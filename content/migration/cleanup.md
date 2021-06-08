---
title: "Cleanup"
chapter: false
weight: 70
---

#### Cleanup

```bash
cd ~/environment/ecsdemo-migration-to-ecs/app
copilot app delete --name userapi --yes
cd ~/environment/ecsdemo-migration-to-ecs/build_ec2_environment
cdk destroy -f
```
