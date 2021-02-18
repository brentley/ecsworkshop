---
title: "Setup the CDK Application"
chapter: false
weight: 31
---

Next, we create the stacks and the CDK infrastructure application itself in `bin/secret-ecs-app.ts`.   
```
import { App } from '@aws-cdk/core';
import { VPCStack } from '../lib/vpc-stack';
import { RDSStack } from '../lib/rds-stack-sm';
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

/* Secrets Manager*/

const ecsStack = new ECSStack(app, "ECSStack", {
    vpc: vpcStack.vpc,
    dbSecretArn: rdsStack.dbSecret.secretArn,
    env: cdkEnv
});

ecsStack.addDependency(rdsStack);
```

Environment variables from inside the Cloud9 environment are passed in via `cdkenv` - the current AWS_ACCOUNT_ID and AWS_REGION setup earlier in the tutorial. 

A new CDK app is created `const App = new App()`, and the aforementioned stacks from `lib` are instantiated.   Into each stack we pass the environment variables.   After we created the VPC, we pass the VPC object into the RDS and ECS stack and add dependencies to ensure the VPC is created before the RDS stack.   

When we create the ECS stack, we pass in the same VPC object along with a reference to the RDS stack's generated `dbSecretArn` so that the ECS stack can look up the appropriate secret.  We also create a dependency so that the ECS stack is created after the RDS Stack in this example. 