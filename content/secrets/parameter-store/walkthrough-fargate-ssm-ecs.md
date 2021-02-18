---
title: "Setup the ECS Cluster in Fargate"
chapter: false
weight: 50
---

To fetch the secrets from the parameter store, we use the `StringParameter.fromStringParameterName` for the plaintext values, and `StringParameter.fromSecureStringParameterAttributes` for the secure value.  We pass those values to the task definition container image options into the `secrets` property via the `fromSsmParameter` method. 

### lib/ecs-fargate-stack-sm.ts
```
import { App, Stack, StackProps, CfnOutput } from '@aws-cdk/core';
import { Vpc } from "@aws-cdk/aws-ec2";
import { Cluster, ContainerImage, Secret as ECSSecret } from "@aws-cdk/aws-ecs";
import { ApplicationLoadBalancedFargateService } from '@aws-cdk/aws-ecs-patterns';
import { StringParameter } from '@aws-cdk/aws-ssm';

export interface ECSStackProps extends StackProps {
  vpc: Vpc
}

export class ECSStack extends Stack {
  constructor(scope: App, id: string, props: ECSStackProps) {
    super(scope, id, props);

    const containerPort = this.node.tryGetContext("containerPort");
    const containerImage = this.node.tryGetContext("containerImage");

    const cluster = new Cluster(this, 'Cluster', {
      vpc: props.vpc
    });

    const DBHOST = StringParameter.fromStringParameterName(this, 'dbEndpoint', 'DBHost');
    const DBPORT = StringParameter.fromStringParameterName(this, 'dbbPort', 'DBPort');
    const DBNAME = StringParameter.fromStringParameterName(this, 'dbName', 'DBName');
    const DBUSER = StringParameter.fromStringParameterName(this, 'dbUser', 'DBUsername');
    const DBPASS = StringParameter.fromSecureStringParameterAttributes(this, 'dbPass', {
      parameterName: 'DBPass',
      version: 1
    });

    const fargateService = new ApplicationLoadBalancedFargateService(this, "FargateService", {
      cluster,
      taskImageOptions: {
        image: ContainerImage.fromRegistry(containerImage),
        containerPort: containerPort,
        enableLogging: true,
        secrets: {
          POSTGRES_USER: ECSSecret.fromSsmParameter(DBUSER),
          POSTGRES_HOST: ECSSecret.fromSsmParameter(DBHOST),
          POSTGRES_PORT: ECSSecret.fromSsmParameter(DBPORT),
          POSTGRES_NAME: ECSSecret.fromSsmParameter(DBNAME),
          POSTGRES_PASS: ECSSecret.fromSsmParameter(DBPASS),
        }
      },
      desiredCount: 1,
      publicLoadBalancer: true
    });

    const outputUrl = fargateService.loadBalancer.loadBalancerDnsName;

    new CfnOutput(this, 'LoadBalancerDNS', { value: outputUrl});
  }
}
```

