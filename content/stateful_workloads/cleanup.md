+++
title = "Cleanup"
chapter = false
weight = 7
+++

#### Cleanup

```bash
aws ecs update-service --cluster $cluster_name --service cloudcmd-rw --desired-count 0
task_arn=$(aws ecs list-tasks --cluster $cluster_name --service-name cloudcmd-rw | jq -r .taskArns[])
aws ecs stop-task --task $task_arn --cluster $cluster_name
aws ecs delete-service --cluster $cluster_name --service cloudcmd-rw
cdk destroy -f
```