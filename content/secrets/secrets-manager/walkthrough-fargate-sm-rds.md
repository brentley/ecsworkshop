---
title: "Setup the RDS Cluster"
chapter: false
weight: 27
---

Next, the RDS Aurora Serverless cluster is created.  

#### lib/rds-stack-serverless-sm.ts

```
import { App, StackProps, Stack, Duration, RemovalPolicy } from "@aws-cdk/core";
import {
    DatabaseSecret, Credentials, ServerlessCluster, DatabaseClusterEngine, ParameterGroup, AuroraCapacityUnit
} from '@aws-cdk/aws-rds';
import { Vpc, Port, SubnetType } from '@aws-cdk/aws-ec2';
import { Secret } from '@aws-cdk/aws-secretsmanager';

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
            vpcSubnets: { subnetType: SubnetType.PUBLIC },
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

Here, another Cloudformation Stack is setup containing the template to build an Aurora Serverless Postgres Cluster.   

The secret to use with RDS is created using the following code:
```
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
```

In this example, a new randomized secret password for the RDS database is created and stored along with all the other parameters needed to connect to the database.   This is all done automatically with Secrets Manager integration with RDS.   When run, the stored secret will look like this:

![Secrets Manager Detail](/images/secrets-manager-detail.png)

The stored secret is passed to the db creation code along with the other context parameters. 