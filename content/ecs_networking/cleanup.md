+++
title = "Clean up"
chapter = false
weight = 70
+++

#### Delete remaining ECS tasks, platform and other resources

```bash
for task in `aws ecs list-tasks --cluster ${ClusterName} --query 'taskArns' --output text`; do aws ecs stop-task --cluster ${ClusterName} --task $task; done
aws cloudformation delete-stack --stack-name $STACK_NAME
```

```bash
# delete IAM roles
aws iam delete-role-policy --role-name $TASK_ROLE_NAME --policy-name $TASK_ROLE_POLICY
aws iam delete-role --role-name $TASK_ROLE_NAME
aws iam detach-role-policy --role-name $EXEC_ROLE_NAME --policy-arn $EXEC_ROLE_POLICY_ARN
aws iam delete-role --role-name $EXEC_ROLE_NAME

# delete CloudWatch log group
aws logs delete-log-group --log-group-name $CW_LOG_GROUP
```