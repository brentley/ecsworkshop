+++
title = "Clean up"
chapter = false
weight = 70
+++

#### Delete remaining ECS tasks, platform and other resources

```bash
# TBD
#aws ecs list-tasks ${ClusterName}
#aws ecs stop-task --cluster ${ClusterName} --task XXX
aws cloudformation delete-stack --stack-name $STACK_NAME
```

```bash
# delete IAM roles
aws iam delete-role --role-name $TASK_ROLE_NAME
aws iam delete-role --role-name $EXEC_ROLE_NAME

# delete CloudWatch log group
aws logs delete-log-group --log-group-name "/aws/ecs/ecs-networking-demo"
```