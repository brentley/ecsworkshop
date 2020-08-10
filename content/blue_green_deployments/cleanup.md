+++
title = "Cleanup"
chapter = false
weight = 10
+++


#### Cleanup

```bash
cd ~/environment/ecs-codepipeline-demo
cdk destroy -f
```

* You will need to manually delete the S3 bucket and ECR repository since they are not empty
