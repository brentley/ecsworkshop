---
title: "Setup the Context Variables"
chapter: false
weight: 44
---

The repository contains a sample application that deploys a Fargate Service running a NodeJS application that connects to a RDS Postgres Instance via credentials stored in Secrets Manager.

#### cdk.json
```
{
  "app": "npx ts-node --prefer-ts-exts bin/secret-ecs-app.ts",
  "context": {
    "@aws-cdk/core:enableStackNameDuplicates": "true",
    "aws-cdk:enableDiffNoFail": "true",
    "@aws-cdk/core:stackRelativeExports": "true",
    "@aws-cdk/aws-ecr-assets:dockerIgnoreSupport": true,
    "@aws-cdk/aws-secretsmanager:parseOwnedSecretName": true,
    "@aws-cdk/aws-kms:defaultKeyPolicies": true,
    "@aws-cdk/aws-s3:grantWriteWithoutAcl": true,
    "vpcName": "ecsSecretsVpc",
    "dbName": "tododb",
    "dbUser": "postgres",
    "dbPort": 5432,
    "containerPort": 4000,
    "containerImage": "mptaws/secretecs"
  }
}
```
First, context variables are setup that the application will consume.   `vpcName`, `dbName`, `dbUser`, `dbPort`, `containerPort` and `containerImage` are specified.  These values will be referenced by using `tryGetContext(<context-value>)`.   Managing context variables outside of the application files is a recommended best practice vs hard-coding values into the scripts. 