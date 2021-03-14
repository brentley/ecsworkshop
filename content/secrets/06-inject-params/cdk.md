---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Within a CDK application, you can pull both plaintext and secure secret parameters via the `aws-cdk/aws-ssm` library.

First, add the `aws-ssm` library to the CDK project.

```bash
npm install @aws-cdk/aws-ssm
```

Then, create a secure SSM parameter
```bash
aws ssm put-parameter --name DEMO_PARAMETER --value "parameter-diagram.png" --type SecureString
```

Next, replace the file `lib/ecs-fargate-stack.ts` with the below code:

```typescript
import { App, Stack, StackProps, CfnOutput } from '@aws-cdk/core';
import { Vpc } from "@aws-cdk/aws-ec2";
import { Cluster, ContainerImage, Secret as ECSSecret } from "@aws-cdk/aws-ecs";
import { ApplicationLoadBalancedFargateService } from '@aws-cdk/aws-ecs-patterns';
import { Secret } from '@aws-cdk/aws-secretsmanager';

//SSM Parameter imports
import { SecretValue } from '@aws-cdk/core';
import { StringParameter, ParameterTier } from "@aws-cdk/aws-ssm";

export interface ECSStackProps extends StackProps {
  vpc: Vpc
  dbSecretArn: string
}

export class ECSStack extends Stack {

  constructor(scope: App, id: string, props: ECSStackProps) {
    super(scope, id, props);

    const containerPort = this.node.tryGetContext("containerPort");
    const containerImage = this.node.tryGetContext("containerImage");
    const creds = Secret.fromSecretCompleteArn(this, 'postgresCreds', props.dbSecretArn);

    const cluster = new Cluster(this, 'Cluster', {
      vpc: props.vpc,
      clusterName: 'fargateClusterDemo'
    });

    const fargateService = new ApplicationLoadBalancedFargateService(this, "fargateService", {
      cluster,
      taskImageOptions: {
        image: ContainerImage.fromRegistry(containerImage),
        containerPort: containerPort,
        enableLogging: true,
        secrets: {
          POSTGRES_DATA: ECSSecret.fromSecretsManager(creds),
        },
        //Get value from SSM
        environment: {
          DEMO_PARAMETER: SecretValue.ssmSecure('DEMO_PARAMETER', '1').toString()
        }
      },
      desiredCount: 1,
      publicLoadBalancer: true,
      serviceName: 'fargateServiceDemo'
    });

    //Set a new value into a SSM parameter
    new StringParameter(this, 'MyValue', {
      allowedPattern: '.*',
      description: 'A new parameter description',
      parameterName: 'NEW_PARAMETER',
      stringValue: "secretValue1234",
      tier: ParameterTier.STANDARD
    });

    new CfnOutput(this, 'LoadBalancerDNS', { value: fargateService.loadBalancer.loadBalancerDnsName });
  }
}
```

Once the deployment is complete, go back to the browser and you should see the app again.  

![working-app](/images/secrets-parameter-store-working.png)