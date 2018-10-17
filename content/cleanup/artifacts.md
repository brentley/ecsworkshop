+++
title = "Artifacts and Stacks"
chapter = false
weight = 30
draft = true
+++

{{% notice info %}}
For safety, CloudFormation doesn't remove these artifact stores by default, so we will with a few aws-cli commands.
{{% /notice %}}

Let's clean up the ECR repositories:
```bash
aws ecr delete-repository --repository-nam ${MU_NAMESPACE}-ecsdemo-frontend --force
aws ecr delete-repository --repository-nam ${MU_NAMESPACE}-ecsdemo-nodejs --force
aws ecr delete-repository --repository-nam ${MU_NAMESPACE}-ecsdemo-crystal --force
```

And now we can clean up the s3 buckets:
```bash
export REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/'
)
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rm --recursive s3://${MU_NAMESPACE}-codedeploy-${REGION}-${ACCOUNT_ID}
aws s3 rm --recursive s3://${MU_NAMESPACE}-codepipeline-${REGION}-${ACCOUNT_ID}
```

Finally, we can clean up the CloudFormation stacks that remain:
```bash
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
Wait for all "mu" stacks, except "iam-common" to delete before continuing.
{{% /notice %}}
