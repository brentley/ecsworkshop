---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Next, lets look at the stacks.   The files in `lib` each represent a Cloudformation Stack containing the component parts of the application infrastructure.  

#### lib/vpc-stack.ts

```ts
import { App, Stack, StackProps, Construct } from '@aws-cdk/core';
import { Vpc, SubnetType } from '@aws-cdk/aws-ec2'

export interface VpcProps extends StackProps {
    maxAzs: number;
}

export class VPCStack extends Stack {
    readonly vpc: Vpc;

    constructor(scope: Construct, id: string, props: VpcProps) {
        super(scope, id, props);

        if (props.maxAzs !== undefined && props.maxAzs <= 1) {
            throw new Error('maxAzs must be at least 2.');
        }

        this.vpc = new Vpc(this, 'ecsWorkshopVPC', {
            cidr: "10.0.0.0/16",
            subnetConfiguration: [
                {
                    cidrMask: 24,
                    name: 'public',
                    subnetType: SubnetType.PUBLIC,
                },
                {
                    cidrMask: 24,
                    name: 'private',
                    subnetType: SubnetType.PRIVATE,
                },
            ],
        });
    }
}
```

The VPC stack creates a new VPC within the AWS account.   The CIDR address space for this VPC is `10.0.0.0./16`.   It will set up 2 public subnets and all the appropriate routing table information automatically.   An interface is setup to pass in the value for `maxAzs` which is set to 2 in the main application. 
