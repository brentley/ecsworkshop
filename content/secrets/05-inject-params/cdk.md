---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Within a CDK application, you can pull both plaintext and secure secret parameters via the `aws-cdk/aws-ssm` library.  This library is included inside the repository's `package.json` file.

This part of the tutorial will demonstrate how to add a secure SSM parameter and use it in the application to display an image that is conditional on the value of the parameter passed via environment variables. 

To create the secure SSM parameter for this tutorial (specifying the name of the image to display which is already present in the application):

```bash
aws ssm put-parameter --name DEMO_PARAMETER --value "static/parameter-diagram.png" --type SecureString
```

You should see the result:

```json
{
    "Tier": "Standard", 
    "Version": 1
}
```

Next, replace the contents of the file `lib/ecs-fargate-stack.ts` with the below code.   This code can also be found in  `lib/ecs-fargate-stack-ssm.ts` for reference.

```bash
cd ~/environment/secret-ecs-cdk-example
cat << EOF > lib/ecs-fargate-stack.ts
import { App, Stack, StackProps, CfnOutput } from '@aws-cdk/core';
import { Vpc } from "@aws-cdk/aws-ec2";
import { Cluster, ContainerImage, Secret as ECSSecret } from "@aws-cdk/aws-ecs";
import { ApplicationLoadBalancedFargateService } from '@aws-cdk/aws-ecs-patterns';
import { Secret } from '@aws-cdk/aws-secretsmanager';

//SSM Parameter imports
import { SecretValue } from '@aws-cdk/core';
import { StringParameter, ParameterTier, ParameterType } from "@aws-cdk/aws-ssm";

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

    //fetch existing parameter from parameter store securely
    const DEMOPARAM = StringParameter.fromSecureStringParameterAttributes(this, 'demo_param', {
      parameterName: 'DEMO_PARAMETER',
      version: 1
    });

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
          //Inject parameter value securely
          DEMO_PARAMETER: ECSSecret.fromSsmParameter(DEMOPARAM),
        },
      },
      desiredCount: 1,
      publicLoadBalancer: true,
      serviceName: 'fargateServiceDemo'
    });

    new CfnOutput(this, 'LoadBalancerDNS', { value: fargateService.loadBalancer.loadBalancerDnsName });
  }
}
EOF
```

After you make the changes, save the file and redeploy the app:

```bash
cdk deploy --all --require-approval never
```

This revision to the stack injects the parameter `DEMO_PARAMETER` into the container via the `secrets` property.

Once the deployment is complete, go back to the browser and you should see the app again with the new image displayed.

![working-app](/images/secrets-parameter-store-working.png)