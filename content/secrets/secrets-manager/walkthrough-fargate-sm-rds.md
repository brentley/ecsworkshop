---
title: "Setup the RDS Instance"
chapter: false
weight: 27
---

Next, the RDS instance is created.  

#### lib/rds-stack-sm.ts

```
import { App, StackProps, Stack, CfnOutput } from "@aws-cdk/core";
import {
    DatabaseSecret, DatabaseInstance, DatabaseInstanceEngine,
    PostgresEngineVersion, Credentials, StorageType
} from '@aws-cdk/aws-rds';
import { Vpc, Port, SubnetType, InstanceType } from '@aws-cdk/aws-ec2';

export interface RDSStackProps extends StackProps {
    vpc: Vpc
}

export class RDSStack extends Stack {

    readonly dbSecret: DatabaseSecret;
    readonly postgresRDSInstance: DatabaseInstance;

    constructor(scope: App, id: string, props: RDSStackProps) {
        super(scope, id, props);

        const dbUser = this.node.tryGetContext("dbUser");
        const dbName = this.node.tryGetContext("dbName");
        const dbPort = this.node.tryGetContext("dbPort");
        const dbInstanceType = this.node.tryGetContext("instanceType");

        this.dbSecret = new DatabaseSecret(this, 'DbSecret', {
            username: dbUser
        });

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
            credentials: Credentials.fromSecret(this.dbSecret, dbUser),
            databaseName: dbName,
            port: dbPort,
        });

        this.postgresRDSInstance.connections.allowFromAnyIpv4(Port.tcp(dbPort));

        new CfnOutput(this, 'POSTGRES_URL', { value: this.postgresRDSInstance.dbInstanceEndpointAddress });

    }
}
```

Here, we setup another Cloudformation Stack containing the template to build a single RDS Postgres Instance.   We pull the in the context variables `dbUser`, `dbName`,`dbPort` and `instanceType`.

The secret to use with RDS is created using the following code:
```
        this.dbSecret = new DatabaseSecret(this, 'DbSecret', {
            username: dbUser
        });
```

In this example, a new randomized secret password for the RDS database is created and stored along with all the other parameters needed to connect to the database.   This is all done automatically with Secrets Manager integration with RDS.   When run, the stored secret will look like this:

![Secrets Manager Detail](/images/secrets-manager-detail.png)

The stored secret is passed to the db creation code along with the other context parameters. 