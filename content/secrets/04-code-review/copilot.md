---
title: "Embedded tab content"
disableToc: true
hidden: true
---

### Deploy our application, service, and environment

{{% notice note %}}

In this section, it is important to match the names as described in order for the tutorial to work (so that it matches the format of the manifest in the tutorial repository):

{{% /notice %}}

```bash
cd ~/environment/secretecs
copilot init
```

{{%expand "Optional Shortcut - pass all parameters through CLI" %}}

```bash
APPNEW=ecsworkshop$(tr -dc a-z0-9 </dev/urandom | head -c 4 ; echo '')  #create a short random string to provide a unique value to the application name.
copilot init --app $APPNEW --name todo-app --type 'Load Balanced Web Service' --dockerfile './Dockerfile' --port 4000 --deploy
```

{{% /expand%}}

* Application Name: `ecsworkshop`  #note this should be unique in your AWS account
* Workload Type: `Load Balanced Web Service`
* Service Name: `todo-app` - this must be left 'as-is' for demo purposes
* Dockerfile: `./Dockerfile`

After a brief moment, you will be prompted to created a local environment.  

* Deploy local test environment: `yes`

{{< figure src="/images/secrets-copilot-init.gif" alt="Secrets Diagram" width="800px" >}}

During this stage of the process, copilot is doing the initial infrastructure setup and preparing to creates a new environment, including creating an ECR repository to store the container build images. 

```text
✔ Proposing infrastructure changes for the ecsworkshop environment.
- Creating the infrastructure for the ecsworkshop environment.           [create complete]  [82.1s]
  - An IAM Role for AWS CloudFormation to manage resources               [create complete]  [19.5s]
  - An ECS cluster to group your services                                [create complete]  [12.7s]
  - An IAM Role to describe resources in your environment                [create complete]  [17.9s]
  - A security group to allow your containers to talk to each other      [create complete]  [4.9s]
  - An Internet Gateway to connect to the public internet                [create complete]  [16.6s]
  - Private subnet 1 for resources with no internet access               [create complete]  [16.4s]
  - Private subnet 2 for resources with no internet access               [create complete]  [16.4s]
  - Public subnet 1 for resources that can access the internet           [create complete]  [16.4s]
  - Public subnet 2 for resources that can access the internet           [create complete]  [16.4s]
  - A Virtual Private Cloud to control networking of your AWS resources  [create complete]  [16.6s]
    Linking account XXXXXXX and region us-west-2 to application ecsworkshop. 
```

Next, copilot pulls the application image from the ECR repository and builds the application, including VPC, Aurora Serverless DB, and deploys the application to a newly created ECS cluster.

Deployment of the app via copilot goes through the following stages:

```text
- Creating the infrastructure for stack ecsworkshop-test-todo-app              [create in progress]  
  - An Addons CloudFormation Stack for your additional AWS resources           [review in progress]  
  - Service discovery for your services to communicate within the VPC          [create complete]    
  - Update your environments shared resources                                  [update in progress]  
    - A security group for your load balancer allowing HTTP and HTTPS traffic  [create in progress] 
  - An IAM Role for the Fargate agent to make AWS API calls on your behalf     [create complete]    
  - A CloudWatch log group to hold your service logs                           [create complete]   
  - An ECS service to run and maintain your tasks in the environment cluster   [not started]         
  - A target group to connect the load balancer to your service                [create complete]   
  - An ECS task definition to group your containers and run them on ECS        [not started]         
  - An IAM role to control permissions for the containers in your tasks        [create complete]   
```

This step in the process takes a few minutes, so let's dive into what is going on behind the scenes.

Copilot creates a new environment by default called `test` which is used throughout the rest of the tutorial.  The manifest file created in the project defines everything needed for a load balanced web application.   Read the full specification for the "Load Balanced Web Service" type at

[https://aws.github.io/copilot-cli/docs/manifest/lb-web-service/](https://aws.github.io/copilot-cli/docs/manifest/lb-web-service/)

Now lets review the manifest file itself:

{{%expand "Click to review copilot/todo-app/manifest.yml" %}}

```yaml
# The manifest for the "todo-app" service.


# Your service name will be used in naming your resources like log groups, ECS services, etc.
name: todo-app
# The "architecture" of the service you're running.
type: Load Balanced Web Service

image:
  # Docker build arguments.
  # For additional overrides: https://aws.github.io/copilot-cli/docs/manifest/lb-web-service/#image-build
  build: ./Dockerfile
  # Port exposed through your container to route traffic to it.
  port: 4000

http:
  # Requests to this path will be forwarded to your service.
  # To match all requests you can use the "/" path.
  path: "/"
  # You can specify a custom health check path. The default is "/".
  # For additional configuration: https://aws.github.io/copilot-cli/docs/manifest/lb-web-service/#http-healthcheck
  # healthcheck: '/'
  # You can enable sticky sessions.
  # stickiness: true

# Number of CPU units for the task.
cpu: 256
# Amount of memory in MiB used by the task.
memory: 512
# Number of tasks that should be running in your service.
count: 1

# Optional fields for more advanced use-cases.
#
variables: # Pass environment variables as key value pairs.
  LOG_LEVEL: info
#
# You can override any of the values defined above by environment.
#environments:
#  test:
#    count: 2               # Number of tasks to run for the "test" environment.
```

Copilot utilizes Cloudformation templates to provision infrastructure behind the scenes.  The above template is generated when `copilot init` is run - but in the case of this tutorial as long as you use the same service name and values, the process will use the file in the repository.

The main values here specify:

* A load balanced web service
* Dockerfile to use for build
* CPU for Fargate task
* Memory for Fargate task
* A section to pass secret values through the SSM Parameter Store
{{% /expand%}}

Next, we create an Aurora Serverless Postgres Database Cluster via the `addons` functionality of copilot.

{{%expand "Click to review copilot/todo-app/addons/db.yml" %}}

Any additional AWS resource can be specified here by adding a cloudformation template to the `copilot\service-name\addons` directory.  This option is also part of the copilot CLI using the `copilot storage init` command.

This template also creates the secret to use with the database and enables credential rotation via a Lambda function. It also adds some missing networking configuration that allows the credential rotation lambda to communicate with Secrets Manager.  It outputs the secret as an environment variable for our application to read.

The template enables parameters to be passed in from copilot, namely `App`, `Env`, and `Name`.  

```yaml
---
AWSTemplateFormatVersion: 2010-09-09

Parameters:
  App:
    Type: String
    Description: Your application's name.
  Env:
    Type: String
    Description: The environment name your service, job, or workflow is being deployed to.
  Name:
    Type: String
    Description: The name of the service, job, or workflow being deployed.
```

Next, we add some missing networking components that allow the private subnets to communicate to Secrets Manager via a NAT Gateway.

```yaml
Resources:
  EipA:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc

  NatGatewayA:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt EipA.AllocationId
      SubnetId:
        !Select [
          0,
          !Split [
            ",",
            { "Fn::ImportValue": !Sub "${App}-${Env}-PublicSubnets" },
          ],
        ]

  RouteTableA:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: { "Fn::ImportValue": !Sub "${App}-${Env}-VpcId" }

  RouteTableAssociationA:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId:
        Ref: RouteTableA
      SubnetId:
        !Select [
          0,
          !Split [
            ",",
            { "Fn::ImportValue": !Sub "${App}-${Env}-PrivateSubnets" },
          ],
        ]

  DefaultRouteA:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId:
        Ref: RouteTableA
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId:
        Ref: NatGatewayA

  EipB:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc

  NatGatewayB:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt EipB.AllocationId
      SubnetId:
        !Select [
          1,
          !Split [
            ",",
            { "Fn::ImportValue": !Sub "${App}-${Env}-PublicSubnets" },
          ],
        ]

  RouteTableB:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: { "Fn::ImportValue": !Sub "${App}-${Env}-VpcId" }

  RouteTableAssociationB:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId:
        Ref: RouteTableB
      SubnetId:
        !Select [
          1,
          !Split [
            ",",
            { "Fn::ImportValue": !Sub "${App}-${Env}-PrivateSubnets" },
          ],
        ]

  DefaultRouteB:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId:
        Ref: RouteTableB
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId:
        Ref: NatGatewayB
```

Next, add the constructs needed for database cluster creation, including the secret for the database stored in AWS Secrets Manager, appropriate db subnets, security groups.  Finally, we attach the secret to the database cluster so that the database knows to pull credentials from secrets manager.  

```yaml
  SecurityGroupfromRDSStackdbCredentialsRotationSecurityGroup:
      Type: AWS::EC2::SecurityGroupIngress
      Properties:
        IpProtocol: tcp
        Description: !Ref 'AWS::StackName'
        FromPort:
          Fn::GetAtt:
            - AuroraDBCluster
            - Endpoint.Port
        GroupId:
          Fn::GetAtt:
            - ClusterSecurityGroup
            - GroupId
        SourceSecurityGroupId:
          Fn::GetAtt:
            - RotationSecurityGroup
            - GroupId
        ToPort:
          Fn::GetAtt:
            - AuroraDBCluster
            - Endpoint.Port

  RotationSecurityGroup:
    Type: 'AWS::EC2::SecurityGroup'
    Properties:
      VpcId: { 'Fn::ImportValue': !Sub '${App}-${Env}-VpcId' }
      GroupDescription: !Ref 'AWS::StackName'
      SecurityGroupEgress:
        - IpProtocol: '-1'
          Description: Allow all outbound traffic by default
          CidrIp: 0.0.0.0/0

  AuroraSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: !Join [ '/', [ !Ref App, !Ref Env, !Ref Name, 'aurora-pg' ] ]
      Description: !Join [ '', [ 'Aurora PostgreSQL Main User Secret ', 'for CloudFormation Stack ', !Ref 'AWS::StackName' ] ]
      GenerateSecretString:
        SecretStringTemplate: '{"username": "postgres"}'
        GenerateStringKey: "password"
        ExcludePunctuation: true
        IncludeSpace: false
        PasswordLength: 16
        
  SecretCredentialPolicy:
    Type: 'AWS::SecretsManager::ResourcePolicy'
    Properties:
      SecretId: !Ref AuroraSecret
      ResourcePolicy:
        Version: 2012-10-17
        Statement:
          - Action: 'secretsmanager:DeleteSecret'
            Resource: '*'
            Effect: Deny
            Principal:
              AWS: !Join 
                - ''
                - - 'arn:'
                  - !Ref 'AWS::Partition'
                  - ':iam::'
                  - !Ref 'AWS::AccountId'
                  - ':root'
     
  DBSubnetGroup:
    Type: 'AWS::RDS::DBSubnetGroup'
    Properties:
      DBSubnetGroupDescription: !Ref 'AWS::StackName'
      SubnetIds: !Split [ ',', { 'Fn::ImportValue': !Sub '${App}-${Env}-PrivateSubnets' } ]

  ClusterSecurityGroup:
    Type: 'AWS::EC2::SecurityGroup'
    Properties:
      SecurityGroupIngress:
        - ToPort: 5432
          FromPort: 5432
          IpProtocol: tcp
          Description: 'from 0.0.0.0/0:5432'
          CidrIp: 0.0.0.0/0
      VpcId: { 'Fn::ImportValue': !Sub '${App}-${Env}-VpcId' }
      GroupDescription: RDS security group
      SecurityGroupEgress:
        - IpProtocol: '-1'
          Description: Allow all outbound traffic by default
          CidrIp: 0.0.0.0/0

  AuroraDBCluster:
    Type: 'AWS::RDS::DBCluster'
    Properties:
      MasterUsername: !Join ['', ['{{resolve:secretsmanager:', !Ref AuroraSecret, ':SecretString:username}}' ]]
      MasterUserPassword: !Join ['', ['{{resolve:secretsmanager:', !Ref AuroraSecret, ':SecretString:password}}' ]]
      DatabaseName: 'tododb'
      Engine: aurora-postgresql
      EngineVersion: '10.7'
      EngineMode: serverless
      EnableHttpEndpoint: true
      StorageEncrypted: true
      DBClusterParameterGroupName: default.aurora-postgresql10
      DBSubnetGroupName: !Ref DBSubnetGroup
      VpcSecurityGroupIds:
        - !Ref ClusterSecurityGroup
      ScalingConfiguration:
        AutoPause: true
        MinCapacity: 2
        MaxCapacity: 8
        SecondsUntilAutoPause: 1000
    DeletionPolicy: Delete

  SecretAuroraClusterAttachment:
    Type: AWS::SecretsManager::SecretTargetAttachment
    Properties:
      SecretId: !Ref AuroraSecret
      TargetId: !Ref AuroraDBCluster
      TargetType: AWS::RDS::DBCluster
  ```


The output shown here is the environment variable the todo application needs to communicate with the database.

```yml
Outputs:
  PostgresData: # injected as POSTGRES_DATA environment variable by Copilot.
    Description: "The JSON secret that holds the database username and password. Fields are 'host', 'dbname', 'username', 'password'"
    Value: !Ref AuroraSecret
```

This output will expose output as a variable called `POSTGRES_DATA` in the container environment.   This environment variable is where the todo application will get its credentials to access the database.

{{% /expand%}}

Once the copilot process is finished, the last step for this tutorial is to get the LoadBalancer URL from copilot and make a call to the application's `migrate` endpoint to populate the database.  

```bash
URL=$(copilot svc show --json | jq -r .routes[].url)
curl -s $URL/migrate | jq
```

This will produce JSON output showing a DROP, CREATE, and UPDATE to populate the database app with an initial todo item. 

To view the app, open a browser and go to the Loadbalancer URL `ECSST-Farga-xxxxxxxxxx.yyyyy.elb.amazonaws.com`:
![Secrets Todo](/images/secrets-todo.png)

This is a fully functional todo app.  Try creating, editing, and deleting todos.  Using the information output from deploy along with the secrets stored in Secrets Manager, connect to the Postgres Database using a database client or the `psql` command line tool to browse the database.

Since this application uses Aurora Serverless, you can also use the query editor in the AWS Management Console - find more information [here](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/query-editor.html). All you need is the secret ARN created by Copilot, you can fetch it at the terminal and copy/paste into the query editor dialog box:

```bash
aws secretsmanager list-secrets | jq -r '.SecretList[].ARN'
```
