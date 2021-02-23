---
title: "Setup the RDS Instance"
chapter: false
weight: 48
---

Before the database is created - a new secret must be created in Parameter store. At a terminal, run 

```
aws ssm put-parameter --name "DBPass" --value "mySecurePassword123456" --type "SecureString"
```
A confirmation will appear:
```
{
    "Version": 1,
    "Tier": "Standard"
}
```
This will create a new Secure Parameter in the parameter store.   Optionally, check the UI for the parameter:

![ssm-details](/images/ssm-details.png)

Next, the RDS instance is created.  

#### lib/rds-stack-serverless-ssm.ts

```
import { App, StackProps, Stack, Duration, RemovalPolicy, SecretValue } from "@aws-cdk/core";
import {
    Credentials, ServerlessCluster, DatabaseClusterEngine, ParameterGroup, AuroraCapacityUnit
} from '@aws-cdk/aws-rds';
import { Vpc, Port, SubnetType } from '@aws-cdk/aws-ec2';
import { StringParameter, ParameterTier } from "@aws-cdk/aws-ssm";

export interface RDSStackProps extends StackProps {
    vpc: Vpc
}

export class RDSStack extends Stack {

    readonly postgresRDSserverless: ServerlessCluster;

    constructor(scope: App, id: string, props: RDSStackProps) {
        super(scope, id, props);

        const dbUser = this.node.tryGetContext("dbUser");
        const stackDBName = this.node.tryGetContext("dbName");
        const stackDBPort = this.node.tryGetContext("dbPort");
        const dbPass = SecretValue.ssmSecure('DBPass', '1');   //NOTE: need to run cli before building stack to create this secret `aws ssm put-parameter --name "DBPass" --value "mySecurePassword123456" --type "SecureString"`

        this.postgresRDSserverless = new ServerlessCluster(this, 'Postgres-rds-serverless', {
            engine: DatabaseClusterEngine.AURORA_POSTGRESQL,
            parameterGroup: ParameterGroup.fromParameterGroupName(this, 'ParameterGroup', 'default.aurora-postgresql10'),
            vpc: props.vpc,
            enableDataApi: true,
            vpcSubnets: { subnetType: SubnetType.PUBLIC },
            credentials: Credentials.fromPassword(dbUser, dbPass),
            scaling: {
                autoPause: Duration.minutes(10), // default is to pause after 5 minutes of idle time
                minCapacity: AuroraCapacityUnit.ACU_8, // default is 2 Aurora capacity units (ACUs)
                maxCapacity: AuroraCapacityUnit.ACU_32, // default is 16 Aurora capacity units (ACUs)
            },
            defaultDatabaseName: stackDBName,
            deletionProtection: false,
            removalPolicy: RemovalPolicy.DESTROY
        });

        this.postgresRDSserverless.connections.allowFromAnyIpv4(Port.tcp(stackDBPort));

        const dbHost = new StringParameter(this, 'DBHost', {
            allowedPattern: '.*',
            description: 'DB Host from CDK Stack Creation',
            parameterName: 'DBHost',
            stringValue: this.postgresRDSserverless.clusterEndpoint.hostname,
            tier: ParameterTier.STANDARD
        });

        const dbPort = new StringParameter(this, 'DBPort', {
            allowedPattern: '.*',
            description: 'DB Port from CDK Stack Creation',
            parameterName: 'DBPort',
            stringValue: stackDBPort.toString(),
            tier: ParameterTier.STANDARD
        });

        const dbName = new StringParameter(this, 'DBName', {
            allowedPattern: '.*',
            description: 'DB Name from CDK Stack Creation',
            parameterName: 'DBName',
            stringValue: stackDBName,
            tier: ParameterTier.STANDARD
        })

        const dbUsername = new StringParameter(this, 'DBUsername', {
            allowedPattern: '.*',
            description: 'DB Username from CDK Stack Creation',
            parameterName: 'DBUsername',
            stringValue: dbUser,
            tier: ParameterTier.STANDARD
        })


    }
}
```

Here, another Cloudformation Stack is setup containing the template to build an Aurora Serverless Postgres Cluster.   The secret to use with RDS is pulled in from parameter store:

```
const dbPass = SecretValue.ssmSecure('DBPass', '1');  
```

After the RDS instance is created, the newly created RDS parameters are saved into parameter store, i.e.:
```
const dbHost = new StringParameter(this, 'DBHost', {
    allowedPattern: '.*',
    description: 'DB Host from CDK Stack Creation',
    parameterName: 'DBHost',
    stringValue: this.postgresRDSserverless.clusterEndpoint.hostname,
    tier: ParameterTier.STANDARD
});
```

This allows the application to access the secrets from the parameter store.  Note that everything but the password is stored in plaintext.  Any parameter stored in SSM may be done securely. 

