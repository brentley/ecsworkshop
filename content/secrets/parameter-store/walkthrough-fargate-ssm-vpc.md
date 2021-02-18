---
title: "Setup the VPC"
chapter: false
weight: 46
---

Next, lets look at the stacks.   The files in `lib` each represent a Cloudformation Stack containing the component parts of the application infrastructure.  

#### lib/vpc-stack.ts

```
import { App, Stack, StackProps } from '@aws-cdk/core';
import { Vpc } from '@aws-cdk/aws-ec2'

export class VPCStack extends Stack {
    readonly vpc: Vpc;

    constructor(scope: App, id: string, props: StackProps) {
        super(scope, id, props);

        const vpcName = scope.node.tryGetContext("vpcName");

        this.vpc = new Vpc(this, `${vpcName}`, {
            cidr: '10.0.0.0/16',
            maxAzs: 2
        })
    }
}
```

The VPC stack creates a new VPC within the AWS account.   The CIDR address space for this VPC is `10.0.0.0./16`.   It will set up 2 public subnets and all the appropriate routing table information automatically.   This is a huge time saver compared to writing out the Cloudformation templates.  It fetches its name from `cdk.json` via `tryGetContext`
