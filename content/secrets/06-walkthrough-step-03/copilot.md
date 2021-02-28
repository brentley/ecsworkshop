---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Copilot handles creation of additional resources via the `addons` folder inside the service folder.   You have the option of creating DynamoDB tables and S3 buckets via the `copilot storage init` command.  To create the Aurora Serverless cluster, a yml file defines the database and its entry in secrets manager.

The template then populates environment variables containing the database credentials and connection information for the todo application to consume. 

With the presence of this file, the creation of this addon stack happens when the copilot app is deployed.

#### copilot/todo-app/addons/db.yml

```yml
Parameters:
  App:
    Type: String
    Description: ECS Workshop
  Env:
    Type: String
    Description: test
  Name:
    Type: String
    Description: Todo App

Resources:
  AuroraKMSCMK:
    Type: 'AWS::KMS::Key'
    DeletionPolicy: Retain
    Properties:
      KeyPolicy:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
            Action: 'kms:*'
            Resource: '*'
          - Effect: Allow
            Principal:
              AWS: '*'
            Action:
              - 'kms:Encrypt'
              - 'kms:Decrypt'
              - 'kms:ReEncrypt*'
              - 'kms:GenerateDataKey*'
              - 'kms:CreateGrant'
              - 'kms:ListGrants'
              - 'kms:DescribeKey'
            Resource: '*'
            Condition:
              StringEquals:
                'kms:CallerAccount': !Ref 'AWS::AccountId'
                'kms:ViaService': !Sub 'rds.${AWS::Region}.amazonaws.com'

  AuroraKMSCMKAlias:
    Type: 'AWS::KMS::Alias'
    DeletionPolicy: Retain
    DependsOn: ['AuroraDBCluster']
    Properties:
      AliasName: !Sub 'alias/${AuroraDBCluster}'
      TargetKeyId: !Ref AuroraKMSCMK

  DBSubnetGroup:
    Type: 'AWS::RDS::DBSubnetGroup'
    Properties:
      DBSubnetGroupDescription: !Ref 'AWS::StackName'
      SubnetIds: !Split [ ',', { 'Fn::ImportValue': !Sub '${App}-${Env}-PrivateSubnets' } ]

  ClusterSecurityGroup:
    Type: 'AWS::EC2::SecurityGroup'
    Properties:
      GroupDescription: !Ref 'AWS::StackName'
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: { 'Fn::ImportValue': !Sub '${App}-${Env}-EnvironmentSecurityGroup' }
          Description: 'Access to environment security group'
      VpcId: { 'Fn::ImportValue': !Sub '${App}-${Env}-VpcId' }

  DBClusterParameterGroup:
    Type: 'AWS::RDS::DBClusterParameterGroup'
    Properties:
      Description: !Ref 'AWS::StackName'
      Family: 'aurora-postgresql10'
      Parameters:
        client_encoding: 'UTF8'

  AuroraMasterSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: !Join [ '/', [ !Ref App, !Ref Env, !Ref Name, 'aurora-pg' ] ]
      Description: !Join [ '', [ 'Aurora PostgreSQL Master User Secret ', 'for CloudFormation Stack ', !Ref 'AWS::StackName' ] ]
      GenerateSecretString:
        SecretStringTemplate: '{"username": "postgres"}'
        GenerateStringKey: "password"
        ExcludeCharacters: '"@/\'
        PasswordLength: 16

  SecretAuroraClusterAttachment:
    Type: AWS::SecretsManager::SecretTargetAttachment
    Properties:
      SecretId: !Ref AuroraMasterSecret
      TargetId: !Ref AuroraDBCluster
      TargetType: AWS::RDS::DBCluster

  AuroraDBCluster:
    Type: 'AWS::RDS::DBCluster'
    Properties:
      MasterUsername: !Join ['', ['{{resolve:secretsmanager:', !Ref AuroraMasterSecret, ':SecretString:username}}' ]]
      MasterUserPassword: !Join ['', ['{{resolve:secretsmanager:', !Ref AuroraMasterSecret, ':SecretString:password}}' ]]
      DatabaseName: 'tododb'
      Engine: aurora-postgresql
      EngineVersion: '10.7'
      EngineMode: serverless
      StorageEncrypted: true
      KmsKeyId: !Ref AuroraKMSCMK
      DBClusterParameterGroupName: !Ref DBClusterParameterGroup
      DBSubnetGroupName: !Ref DBSubnetGroup
      VpcSecurityGroupIds:
        - !Ref ClusterSecurityGroup
      ScalingConfiguration:
        AutoPause: true
        MinCapacity: 2
        MaxCapacity: 8
        SecondsUntilAutoPause: 1000

Outputs:
  PostgresHost: # injected as POSTGRES_HOST environment variable by Copilot.
    Description: 'The connection endpoint for the DB cluster.'
    Value: !Join ['', ['{{resolve:secretsmanager:', !Ref AuroraMasterSecret, ':SecretString:host}}' ]]

  PostgresPass: # injected as POSTGRES_PASS environment variable by Copilot.
    Description: 'The secret that username and password.'
    Value: !Join ['', ['{{resolve:secretsmanager:', !Ref AuroraMasterSecret, ':SecretString:password}}' ]]
    
  PostgresUser: # injected as POSTGRES_USER environment variable by Copilot.
    Description: 'username'
    Value: !Join ['', ['{{resolve:secretsmanager:', !Ref AuroraMasterSecret, ':SecretString:username}}' ]]
    
  PostgresName: # injected as POSTGRES_NAME environment variable by Copilot.
    Description: 'db name'
    Value: !Join ['', ['{{resolve:secretsmanager:', !Ref AuroraMasterSecret, ':SecretString:dbname}}' ]]
    
  PostgresPort: # injected as POSTGRES_PORT environment variable by Copilot.
    Description: 'port'
    Value: !Join ['', ['{{resolve:secretsmanager:', !Ref AuroraMasterSecret, ':SecretString:port}}' ]]
```