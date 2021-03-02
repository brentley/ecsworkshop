---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Next, create the stacks and the CDK infrastructure application itself in `bin/secret-ecs-app.ts`.   
```ts
import { App } from '@aws-cdk/core';
import { VPCStack } from '../lib/vpc-stack';
import { RDSStack } from '../lib/rds-stack';
import { ECSStack } from '../lib/ecs-fargate-stack';

const app = new App();

const vpcStack = new VPCStack(app, 'VPCStack', {
    maxAzs: 2
});

const rdsStack = new RDSStack(app, 'RDSStack', {
    vpc: vpcStack.vpc,
});

rdsStack.addDependency(vpcStack);

const ecsStack = new ECSStack(app, "ECSStack", {
    vpc: vpcStack.vpc,
    dbSecretArn: rdsStack.dbSecret.secretArn,
});

ecsStack.addDependency(rdsStack);
```

A new CDK app is created `const App = new App()`, and the aforementioned stacks from `lib` are instantiated.  After creating the VPC, the VPC object is passed into the RDS and ECS stack and add dependencies to ensure the VPC is created before the RDS stack.   

When creating the ECS stack, the same VPC object is passed along with a reference to the RDS stack generated `dbSecretArn` so that the ECS stack can look up the appropriate secret.  A dependency is created so that the ECS stack is created after the RDS Stack in this example. 