---
title: "Setup the RDS Instance"
chapter: false
weight: 48
---

Before the database is created - a new secret must be created in Parameter store. At a terminal, run 

```
aws ssm put-parameter --name "DBPass" --value "mySecurePassword123456" --type "SecureString"
```
You will see a confirmation in the terminal:
```
{
    "Version": 1,
    "Tier": "Standard"
}
```
This will create a new Secure Parameter in the parameter store.   You can validate by checking the UI:

![ssm-details](/images/ssm-details.png)

Next, the RDS instance is created.  

#### lib/rds-stack-ssm.ts

```
import { App, StackProps, Stack, CfnOutput, SecretValue } from "@aws-cdk/core";
import {
    DatabaseInstance, DatabaseInstanceEngine,
    PostgresEngineVersion, Credentials, StorageType
} from '@aws-cdk/aws-rds';
import { Vpc, Port, SubnetType, InstanceType } from '@aws-cdk/aws-ec2';
import { StringParameter, ParameterTier } from "@aws-cdk/aws-ssm";


export interface RDSStackProps extends StackProps {
    vpc: Vpc
}

export class RDSStack extends Stack {

    readonly postgresRDSInstance: DatabaseInstance;

    constructor(scope: App, id: string, props: RDSStackProps) {
        super(scope, id, props);

        const dbUser = this.node.tryGetContext("dbUser");
        const stackDBName = this.node.tryGetContext("dbName");
        const stackDBPort = this.node.tryGetContext("dbPort");
        const dbInstanceType = this.node.tryGetContext("instanceType");
        const dbPass = SecretValue.ssmSecure('DBPass', '1');   

        this.postgresRDSInstance = new DatabaseInstance(this, 'Postgres-rds-instance', {
            engine: DatabaseInstanceEngine.postgres({
                version: PostgresEngineVersion.VER_12_4
            }),
            instanceType: new InstanceType(dbInstanceType),
            vpc: props.vpc,
            vpcSubnets: { subnetType: SubnetType.PUBLIC },
            storageEncrypted: false,
            multiAz: false,
            autoMinorVersionUpgrade: false,
            allocatedStorage: 25,
            storageType: StorageType.GP2,
            deletionProtection: false,
            credentials: Credentials.fromPassword(dbUser, dbPass),
            databaseName: stackDBName,
            port: stackDBPort,
        });

        this.postgresRDSInstance.connections.allowFromAnyIpv4(Port.tcp(stackDBPort));

        new CfnOutput(this, 'POSTGRES_URL', { value: this.postgresRDSInstance.dbInstanceEndpointAddress });

        const dbHost = new StringParameter(this, 'DBHost', {
            allowedPattern: '.*',
            description: 'DB Host from CDK Stack Creation',
            parameterName: 'DBHost',
            stringValue: this.postgresRDSInstance.dbInstanceEndpointAddress,
            tier: ParameterTier.STANDARD
        });

        const dbPort = new StringParameter(this, 'DBPort', {
            allowedPattern: '.*',
            description: 'DB Port from CDK Stack Creation',
            parameterName: 'DBPort',
            stringValue: this.postgresRDSInstance.dbInstanceEndpointPort,
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

Here, we setup another Cloudformation Stack containing the template to build a single RDS Postgres Instance.   We pull the in the context variables `dbUser`, `dbName`,`dbPort` and `instanceType`.

The secret to use with RDS is pulled in from parameter store:
```
const dbPass = SecretValue.ssmSecure('DBPass', '1');  
```
After the RDS instance is created, we store the newly created RDS parameters into parameter store, i.e.:
```
const dbHost = new StringParameter(this, 'DBHost', {
    allowedPattern: '.*',
    description: 'DB Host from CDK Stack Creation',
    parameterName: 'DBHost',
    stringValue: this.postgresRDSInstance.dbInstanceEndpointAddress,
    tier: ParameterTier.STANDARD
});
```

This allows the application to access the secrets from the parameter store.  Note that everything but the password is stored in plaintext.  You can choose to store these securely. 

