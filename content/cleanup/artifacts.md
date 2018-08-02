+++
title = "Artifacts and Stacks"
chapter = false
weight = 3
+++

{{% notice info %}}
For safety, CloudFormation doesn't remove these artifact stores by default, so we will with a few aws-cli commands.
{{% /notice %}}

Let's clean up the ECR repositories:
```
aws ecr delete-repository --repository-nam ${MU_NAMESPACE}-ecsdemo-frontend --force
aws ecr delete-repository --repository-nam ${MU_NAMESPACE}-ecsdemo-nodejs --force
aws ecr delete-repository --repository-nam ${MU_NAMESPACE}-ecsdemo-crystal --force
```

And now we can clean up the s3 buckets:
```
aws s3 rm --recursive s3://${MU_NAMESPACE}-codedeploy-us-east-1-${ACCOUNT_ID}
aws s3 rm --recursive s3://${MU_NAMESPACE}-codepipeline-us-east-1-${ACCOUNT_ID}
```

Finally, we can clean up the CloudFormation stacks that remain:
```
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-iam-service-ecsdemo-frontend-acceptance
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-iam-service-ecsdemo-frontend-production
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-iam-service-ecsdemo-nodejs-acceptance
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-iam-service-ecsdemo-nodejs-production
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-iam-service-ecsdemo-crystal-acceptance
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-iam-service-ecsdemo-crystal-production

aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-repo-ecsdemo-frontend
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-repo-ecsdemo-nodejs
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-repo-ecsdemo-crystal

aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-bucket-codedeploy
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-bucket-codepipeline
```
{{% notice warning %}}
Wait for all "mu" stacks to delete before deleting the stack with the name "iam-common"
{{% /notice %}}

Lastly, we can delete the IAM role that CloudFormation used to build and manage the other CloudFormation stacks:
```
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-iam-common
```
