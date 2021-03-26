---
title: "Embedded tab content"
disableToc: true
hidden: true
---

### Deploy our application, service, and environment

First, let's test the existing code for any errors.

```bash
cd ~/environment/secret-ecs-cdk-example
cdk synth
```

This creates the cloudformation templates which output to a local directory `cdk.out`.   Successful output will contain (ignore any warnings generated):

```bash
Successfully synthesized to /home/ec2-user/environment/secret-ecs-cdk-example/cdk.out
Supply a stack id (VPCStack, RDSStack, ECSStack) to display its template.
```

(Note this is not a required step as `cdk deploy` will generate the templates again - this is an intermediary step to ensure there are no errors in the stack before proceeding.  If you encounter errors here stop and address them before deployment.)

Then, to deploy this application and all of its stacks, run:

```bash
cdk deploy --all --require-approval never --outputs-file result.json
```

The process takes approximately 10 minutes.  The results of all the actions will be stored in `result.json` for later reference.

{{%expand "Expand to view deployment screenshots" %}}
![CDK Output 1](/images/cdk-output-1.png)
![CDK Output 2](/images/cdk-output-2.png)
{{% /expand%}}

### Code Review

Let's review whats happening behind the scenes.

The repository contains a sample application that deploys a ***ECS Fargate Service***.  The service runs this NodeJS application that connects to a ***AWS RDS Aurora Serverless Database Cluster***.  The credentials for this application are stored in ***AWS Secrets Manager***.

First, let's look at the application context variables:

{{%expand "Review cdk.json" %}}

```json
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
    "dbName": "tododb",
    "dbUser": "postgres",
    "dbPort": 5432,
    "containerPort": 4000,
    "containerImage": "public.ecr.aws/o0u3i9v5/secret-ecs-repo"
  }
}
```

Custom CDK context variables are added to the JSON for the application to consume:

* `dbName` - name of the target database for the tutorial
* `dbUser` - database username
* `dbPort` - database port
* `containerPort` - port on which the container in the ECS cluster runs
* `containerImage` - image name that will be deployed from ECR

These values will be referenced by using the function `tryGetContext(<context-value>)` throughout the rest of the application.
{{% /expand%}}

Next, let's look at the Cloudformation stacks constructs.   The files in `lib` each represent a Cloudformation Stack containing the component parts of the application infrastructure.  

{{%expand "Review lib/vpc-stack.ts" %}}

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

The VPC stack creates a new VPC within the AWS account.   The CIDR address space for this VPC is `10.0.0.0./16`.   It will set up 2 public subnets with NAT Gateways and 2 private subnets with all the appropriate routing information automatically.   An interface is setup to pass in the value for `maxAzs` which is set to 2 in the main application.
{{% /expand%}}

{{%expand "Review lib/rds-stack.ts" %}}

```ts
import { App, StackProps, Stack, Duration, RemovalPolicy } from "@aws-cdk/core";
import {
    DatabaseSecret, Credentials, ServerlessCluster, DatabaseClusterEngine, ParameterGroup, AuroraCapacityUnit
} from '@aws-cdk/aws-rds';
import { Vpc, Port, SubnetType } from '@aws-cdk/aws-ec2';
import { Secret, SecretRotation, SecretRotationApplication } from '@aws-cdk/aws-secretsmanager';

export interface RDSStackProps extends StackProps {
    vpc: Vpc
}

export class RDSStack extends Stack {

    readonly dbSecret: DatabaseSecret;
    readonly postgresRDSserverless: ServerlessCluster;

    constructor(scope: App, id: string, props: RDSStackProps) {
        super(scope, id, props);

        const dbUser = this.node.tryGetContext("dbUser");
        const dbName = this.node.tryGetContext("dbName");
        const dbPort = this.node.tryGetContext("dbPort");

        this.dbSecret = new Secret(this, 'dbCredentialsSecret', {
            secretName: "serverless-credentials",
            generateSecretString: {
                secretStringTemplate: JSON.stringify({
                    username: dbUser,
                }),
                excludePunctuation: true,
                includeSpace: false,
                generateStringKey: 'password'
            }
        });

        this.postgresRDSserverless = new ServerlessCluster(this, 'postgresRdsServerless', {
            engine: DatabaseClusterEngine.AURORA_POSTGRESQL,
            parameterGroup: ParameterGroup.fromParameterGroupName(this, 'ParameterGroup', 'default.aurora-postgresql10'),
            vpc: props.vpc,
            enableDataApi: true,
            vpcSubnets: { subnetType: SubnetType.PRIVATE },
            credentials: Credentials.fromSecret(this.dbSecret, dbUser),
            scaling: {
                autoPause: Duration.minutes(10), // default is to pause after 5 minutes of idle time
                minCapacity: AuroraCapacityUnit.ACU_8, // default is 2 Aurora capacity units (ACUs)
                maxCapacity: AuroraCapacityUnit.ACU_32, // default is 16 Aurora capacity units (ACUs)
            },
            defaultDatabaseName: dbName,
            deletionProtection: false,
            removalPolicy: RemovalPolicy.DESTROY
        });

        this.postgresRDSserverless.connections.allowFromAnyIpv4(Port.tcp(dbPort));
    }
}

```

Here, another Cloudformation Stack is setup containing the template to build an RDS Aurora Serverless Postgres Cluster.

The credentials to use with RDS are created with the following code:

```ts
        this.dbSecret = new Secret(this, 'dbCredentialsSecret', {
            secretName: `ecsworkshop/test/todo-app/aurora-pg`,
            generateSecretString: {
                secretStringTemplate: JSON.stringify({
                    username: dbUser,
                }),
                excludePunctuation: true,
                includeSpace: false,
                generateStringKey: 'password'
            }
        });
```

In this example, a new randomized secret password for the RDS database is created and stored along with all the other parameters needed to connect to the database.   This is all done automatically through Secrets Manager integration with RDS.   When run, the stored credentials within Secrets Manager will look like this:

![Secrets Manager Detail](/images/secrets-manager-detail.png)

The stored credentials are passed to the DB along with the other context parameters.

A key feature in AWS Secrets Manager is the ability to rotate credentials automatically as a security best practice. In order to setup a new credentials rotation, a block is added in the constructor of `lib/rds-stack.ts`.

```ts
        new SecretRotation(
            this,
            secretName: `ecsworkshop/test/todo-app/aurora-pg`,
            {
                secret: this.dbSecret,
                application: SecretRotationApplication.POSTGRES_ROTATION_SINGLE_USER,
                vpc: props.vpc,
                vpcSubnets: { subnetType: SubnetType.PRIVATE },
                target: this.postgresRDSserverless,
                automaticallyAfter: Duration.days(30),
            }
        );
```

Every 30 days, the secret will be rotated and will automatically configure a Lambda function to trigger the rotation using the `single user` method.  More information on the lambdas and methods for credential rotation can be found [here](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_available-rotation-templates.html)

{{% /expand%}}

{{%expand "Review lib/ecs-fargate-stack.ts" %}}

Finally, the ECS service stack is defined in `lib/ecs-fargate-stack.ts`

The ECS Fargate cluster application is created here using the `ecs-patterns` library of the CDK.   This automatically creates the service from a given `containerImage` and sets up the code for a load balancer that is connected to the cluster and is public-facing.   The key benefit here is not having to manually add all the boilerplate code to make the application accessible to the world.   CDK simplifies infrastructure creation by abstraction.

The stored credentials created in the RDS Stack are read from Secrets Manager and passed to our container task definition via the `secrets` property.  The secrets unique ARN is passed into this stack as a parameter `dbSecretArn`.

```ts
import { App, Stack, StackProps } from '@aws-cdk/core';
import { Vpc } from "@aws-cdk/aws-ec2";
import { Cluster, ContainerImage, Secret as ECSSecret } from "@aws-cdk/aws-ecs";
import { ApplicationLoadBalancedFargateService } from '@aws-cdk/aws-ecs-patterns';
import { Secret } from '@aws-cdk/aws-secretsmanager';

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
          POSTGRES_DATA: ECSSecret.fromSecretsManager(creds)
        }
      },
      desiredCount: 1,
      publicLoadBalancer: true,
      serviceName: 'fargateServiceDemo'
    });
  }
}
```

{{% /expand%}}

{{%expand "Review bin/secret-ecs-app.ts" %}}
Finally, the stacks and the CDK infrastructure application itself are created in `bin/secret-ecs-app.ts`, the entry point for the cdk defined in the `cdk.json` mentioned earlier.

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

A new CDK app is created `const App = new App()`, and the aforementioned stacks from `lib` are instantiated.  After creating the VPC, the VPC object is passed into the RDS and ECS stacks.  Dependencies are added to ensure the VPC is created before the RDS stack.

When creating the ECS stack, the same VPC object is passed along with a reference to the RDS stack generated `dbSecretArn` so that the ECS stack can look up the appropriate secret.  A dependency is created so that the ECS stack is created after the RDS Stack.
{{% /expand%}}

After deployment finishes, the last step for this tutorial is to get the LoadBalancer URL and run the migration which populates the database.

```bash
url=$(jq -r '.ECSStack.LoadBalancerDNS' result.json)
curl -s $url/migrate | jq
```

(Note that the migration may take a few seconds to connect and run.)

The custom method `migrate` creates the database schema and a single row of data for the sample application. It is part of the sample application in this tutorial.

To view the app, open a browser and go to the Load Balancer URL `ECSST-Farga-xxxxxxxxxx.yyyyy.elb.amazonaws.com` (the URL is clickable in the Cloud9 interface):
![Secrets Todo](/images/secrets-todo.png)

This is a fully functional todo app.  Try creating, editing, and deleting todo items.  Using the information output from deploy along with the secrets stored in Secrets Manager, connect to the Postgres Database using a database client or the `psql` command line tool to browse the database.

As an added benefit of using RDS Aurora Postgres Serverless, you can also use the query editor in the AWS Management Console - find more information **[here](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/query-editor.html)**. All you need is the secret ARN created during stack creation.  Fetch this value at the Cloud9 terminal and copy/paste into the query editor dialog box.   Use the database name `tododb` as the target database to connect.

```bash
aws secretsmanager list-secrets | jq -r '.SecretList[].ARN'
```
