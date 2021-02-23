---
title: "Setup the CDK Application"
chapter: false
weight: 31
---

Next, create the stacks and the CDK infrastructure application itself in `bin/secret-ecs-app.ts`.   
```
import { App } from '@aws-cdk/core';
import { VPCStack } from '../lib/vpc-stack';
import { RDSStack } from '../lib/rds-stack-serverless-sm';
import { ECSStack } from '../lib/ecs-fargate-stack-sm';

const cdkEnv = {
    account: process.env.AWS_ACCOUNT_ID,
    region: process.env.AWS_REGION
}

const app = new App();

const vpcStack = new VPCStack(app, 'VPCStack', {
    env: cdkEnv
});

const rdsStack = new RDSStack(app, 'RDSStack', {
    vpc: vpcStack.vpc,
    env: cdkEnv
});

rdsStack.addDependency(vpcStack);

const ecsStack = new ECSStack(app, "ECSStack", {
    vpc: vpcStack.vpc,
    dbSecretArn: rdsStack.dbSecret.secretArn,
    env: cdkEnv
});

ecsStack.addDependency(rdsStack);
```

Environment variables from inside the Cloud9 environment are passed in via `cdkEnv` - the current AWS_ACCOUNT_ID and AWS_REGION setup earlier in the tutorial. 

A new CDK app is created `const App = new App()`, and the aforementioned stacks from `lib` are instantiated.   Into each stack the environment variables are passed.   After creating the VPC, the VPC object is passed into the RDS and ECS stack and add dependencies to ensure the VPC is created before the RDS stack.   

When creating the ECS stack, the same VPC object is passed along with a reference to the RDS stack generated `dbSecretArn` so that the ECS stack can look up the appropriate secret.  A dependency is created so that the ECS stack is created after the RDS Stack in this example. 