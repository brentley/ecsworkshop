---
title: "Adding Credential Rotation"
chapter: false
weight: 28
---

An added benefit of using AWS Secrets Manager to maintain sensitive credentials is the ability to rotate credentials on a regular basis.   In order to setup a new rotation, add a block inside the constructor of `lib/rds-stack-serverless.ts`.

```ts
        new SecretRotation(
            this,
            `db-creds-rotation`,
            {
                secret: this.dbSecret,
                application: SecretRotationApplication.POSTGRES_ROTATION_SINGLE_USER,
                vpc: props.vpc,
                target: this.postgresRDSserverless,
                automaticallyAfter: Duration.days(30),
            }
        )
```

This code will create a new secrets rotation every 30 days, and will automatically configure a Lambda function to trigger the rotation.  This adds a best practice for security with minimal code added.

{{%expand "Click here to expand full code of rds-stack-serverless.ts" %}}
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

        this.dbSecret = new Secret(this, 'DBCredentialsSecret', {
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

        this.postgresRDSserverless = new ServerlessCluster(this, 'Postgres-rds-serverless', {
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

        new SecretRotation(
            this,
            `db-creds-rotation`,
            {
                secret: this.dbSecret,
                application: SecretRotationApplication.POSTGRES_ROTATION_SINGLE_USER,
                vpc: props.vpc,
                target: this.postgresRDSserverless,
                automaticallyAfter: Duration.days(30),
            }
        );
    }
}

```
 {{% /expand%}}






