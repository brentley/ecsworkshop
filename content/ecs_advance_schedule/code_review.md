---
title: Code Review
chapter: false
weight: 20
---

#### 3. Navigate to the platform repo

```bash
$ cd ~/environment/ecsworkshop/
```

We are defining our deployment configuration via code. Let’s look through the code to better understand how the CloudFormation stack is going to create resources. 

#### 3.2 Deploying Networking CFN Stack:

Create standard networking resources (VPC, Public and Private Subnets) using the following AWS CloudFormation (CFN) template, naming the stack as `ecsworkshop-vpc`:

```bash
$ aws cloudformation create-stack \
    --stack-name=ecsworkshop-vpc \
    file://ecsworkshop-vpc.yaml \
    --capabilities CAPABILITY_NAMED_IAM
```

As a part of creating the networking infrastructure, we will be creating a VPC and a couple of Public and Private Subnets using the below:
[Image: Screen Shot 2021-04-23 at 7.41.22 PM.png]
Once the above CFN stack is ready (reached CREATE_COMPLETE state), the stack will export values namely `VPCId`, `SecurityGroup` , `Public & Private SubnetIds`. We will need these details to create the ECS Container Instances. Following is the CFN `DescribeStack` API’s output, which verifies the creation of networking resources:

```bash
$ aws cloudformation describe-stacks --stack-name ecsworkshop-vpc --query 'Stacks[*].Outputs' --output table
-------------------------------------------------------------------------------------------------------------------------------------
|                                                          DescribeStacks                                                           |
+--------------------+------------------------------------+-------------------+-----------------------------------------------------+
|     Description    |            ExportName              |     OutputKey     |                     OutputValue                     |
+--------------------+------------------------------------+-------------------+-----------------------------------------------------+
|  Private Subnets   |  ecsworkshop-vpc-PrivateSubnetIds  |  PrivateSubnetIds |  subnet-056b33da478b11f58,subnet-07a7ef29d05b2ada5  |
|  Public Subnets    |  ecsworkshop-vpc-PublicSubnetIds   |  PublicSubnetIds  |  subnet-00f53ccb59fba3013,subnet-075535e0065bee628  |
|  ECS Security Group|  ecsworkshop-vpc-SecurityGroups    |  SecurityGroups   |  sg-06767fd76e0421a4e                               |
|  The VPC Id        |  ecsworkshop-vpc-VpcId             |  VpcId            |  vpc-074d610367de94848                              |
+--------------------+------------------------------------+-------------------+-----------------------------------------------------+
```

#### 3.3 Deploying the Cluster Resources:

Now, let’s create the ECS Cluster infrastructure, using the following command. In this stack deployment, we are importing the VPC, Security Group, and Subnets from the VPC base platform stack. 

```bash
aws cloudformation create-stack \
    --stack-name=ecs-demo \
    --template-body=ecsworkshop-demo.yaml \
    --capabilities CAPABILITY_NAMED_IAM
```

The above command creates the following AWS resources: ECS Cluster, Launch Configuration,  AutoScaling Groups. We are going to create two AutoScaling Groups (ARM64 and GPU based).

To retrieve an Amazon ECS-optimized Amazon Linux 2 (arm64) AMI manually, following is the AWS SSM CLI command:

```bash
aws ssm get-parameters —names /aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended
```

To retrieve an Amazon ECS GPU-optimized AMI manually, following is the AWS CLI command:

```bash
aws ssm get-parameters —names /aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended
```

#### 3.4 ARM based task deployment code

For the ARM based capacity provider in the ECS cluster, there are quite a few resources that have to be created to start Container resources to run ARM based tasks. Those resources are the ECS Cluster, AutoScaling Group, Capacity Provider and the Task Definition with ARM based docker image configuration and PlacementConstraints configuration.  

```yaml
Resources:
# Shared ECS Cluster. 
  ECSCluster:
    Type: AWS::ECS::Cluster

# ARM64 based Launch Configuration. 
  ArmASGLaunchConfiguration:
    Type: AWS::AutoScaling::LaunchConfiguration
    Properties:
      ImageId: !Ref ArmLatestAmiId
      SecurityGroups: !Split
        - ','
        - Fn::ImportValue: !Sub "${VPCStackParameter}-SecurityGroups"
      InstanceType: !Ref 'ArmInstanceType'
      IamInstanceProfile: !Ref 'EC2InstanceProfile'
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash -xe
          echo ECS_CLUSTER=${ECSCluster} >> /etc/ecs/ecs.config
          yum install -y aws-cfn-bootstrap
          /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource ArmECSAutoScalingGroup --region ${AWS::Region}

 # AutoScalingGroup to launch Container Instances using ARM64 Launch Configuration.  
  ArmECSAutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      NewInstancesProtectedFromScaleIn: true
      VPCZoneIdentifier: !Split
        - ','
        - Fn::ImportValue: !Sub "${VPCStackParameter}-PrivateSubnetIds"
      LaunchConfigurationName: !Ref 'ArmASGLaunchConfiguration'
      MinSize: '0'
      MaxSize: !Ref 'MaxSize'
      DesiredCapacity: !Ref 'DesiredCapacity'
      Tags:
        - Key: Name
          Value: !Sub 'ARM64-${ECSCluster}'
          PropagateAtLaunch: true
    CreationPolicy:
      ResourceSignal:
        Timeout: PT15M
    UpdatePolicy:
      AutoScalingReplacingUpdate:
        WillReplace: true

#Capacity Provider configuration to create CapacityProvider for ARM64 ASG. Capacity Provider needs ARM ASG Arn, 
# so CloudFormation customer resource ARMClusterResource will make describe API call to ARM ASG to get the desired value. 
  ArmECSCapacityProvider:
    Type: AWS::ECS::CapacityProvider
    Properties:
        AutoScalingGroupProvider:
            AutoScalingGroupArn: !Select [0, !GetAtt ARMCustomResource.Data ]
            ManagedScaling:
                MaximumScalingStepSize: 10
                MinimumScalingStepSize: 1
                Status: ENABLED
                TargetCapacity: 100
            ManagedTerminationProtection: ENABLED


```

A task placement constraint is a rule that is considered during task placement. Out of the 2 supported types of task placement constraints, we will be using  [memberOf](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html). From the available expressions, we will be using ecs.cpu-architecture to place the task(s) on the desired CPU Architecture of the Container Instance. Below is an example for placing task(s) on ARM64 Architecture.
```yaml
# ECS Task Definition for ARM64 Instance type. PlacementConstraints properties are setting the desired cpu-architecture to arm64.
  Arm64taskdefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Join ['', [!Ref 'AWS::StackName', -arm64]]
      PlacementConstraints: 
        - Type: memberOf
          Expression: 'attribute:ecs.cpu-architecture == arm64'
      ContainerDefinitions:
      - Name: simple-arm64-app
        Cpu: 10
        Command:
          - sh
          - '-c'
          - 'uname -a'
        Essential: true
        Image: public.ecr.aws/amazonlinux/amazonlinux:latest
        Memory: 200
        LogConfiguration:
          LogDriver: awslogs
          Options:
            awslogs-group: !Ref 'CloudwatchLogsGroup'
            awslogs-region: !Ref 'AWS::Region'
            awslogs-stream-prefix: ecs-arm64-demo-app

```

#### **3.5 GPU based task deployment code**

Likewise, for GPU base capacity provider in ECS cluster, there are quite a few resources that have to be created to start the Container resources to run GPU base task. Those resources are AutoScaling Group, Capacity Provider and Task Definition with GPU based docker image configuration and PlacementConstraints configuration.  

```yaml
# GPU based Launch Configuration. 
  GpuASGLaunchConfiguration:
    Type: AWS::AutoScaling::LaunchConfiguration
    Properties:
      ImageId: !Ref GPULatestAmiId
      # SecurityGroups: [!Ref 'EcsSecurityGroup']
      SecurityGroups: !Split
        - ','
        - Fn::ImportValue: !Sub "${VPCStackParameter}-SecurityGroups"
      InstanceType: !Ref 'GpuInstanceType'
      IamInstanceProfile: !Ref 'EC2InstanceProfile'
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash -xe
          echo ECS_CLUSTER=${ECSCluster} >> /etc/ecs/ecs.config
          yum install -y aws-cfn-bootstrap
          /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource GpuECSAutoScalingGroup --region ${AWS::Region}

# AutoScalingGroup to launch Container Instances using GPU Launch Configuration.  
  GpuECSAutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      NewInstancesProtectedFromScaleIn: true
      VPCZoneIdentifier: !Split
        - ','
        - Fn::ImportValue: !Sub "${VPCStackParameter}-PrivateSubnetIds"
      LaunchConfigurationName: !Ref 'GpuASGLaunchConfiguration'
      MinSize: '0'
      MaxSize: !Ref 'MaxSize'
      DesiredCapacity: !Ref 'DesiredCapacity'
      Tags:
        - Key: Name
          Value: !Sub 'GPU-${ECSCluster}'
          PropagateAtLaunch: true
    CreationPolicy:
      ResourceSignal:
        Timeout: PT15M
    UpdatePolicy:
      AutoScalingReplacingUpdate:
        WillReplace: true

#Capacity Provider configuration to create CapacityProvider for GPU ASG. Capacity Provider needs GPU ASG Arn, 
# so CloudFormation customer resource ARMClusterResource will make describe API call to GPU ASG to get the desired value. 
  GpuECSCapacityProvider:
    Type: AWS::ECS::CapacityProvider
    Properties:
        AutoScalingGroupProvider:
            AutoScalingGroupArn: !Select [1, !GetAtt ARMCustomResource.Data ]
            ManagedScaling:
                MaximumScalingStepSize: 10
                MinimumScalingStepSize: 1
                Status: ENABLED
                TargetCapacity: 100
            ManagedTerminationProtection: ENABLED
  

```
As explained above in ARM64 Task definition, we will be using ecs.instance-type attribute to place the task(s) on the desired InstanceType of the Container Instance. Below is an example for placing task(s) on GPU Architecture.
Note: For deploying tasks which requires GPU support, we will be using `instance-type` attribute because GPU base family type is supported in specific instance types only. We can opt the desired instance type from the list of declared/supported instance types while creating the AWS CloudFormation stack.

```yaml
# ECS Task Definition for GPU Instance type. PlacementConstraints properties are setting the desired cpu-architecture to gpu.
  Gputaskdefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Join ['', [!Ref 'AWS::StackName', -gpu]]
      PlacementConstraints: 
        - Type: memberOf
          Expression: !Sub 'attribute:ecs.instance-type == ${GpuInstanceType}'
      ContainerDefinitions:
      - Name: simple-gpu-app
        Cpu: 100
        Essential: true
        Image: nvidia/cuda:11.0-base
        Memory: 80
        ResourceRequirements:
          - Type: GPU
            Value: '1'
        Command:
          - sh
          - '-c'
          - nvidia-smi
        LogConfiguration:
          LogDriver: awslogs
          Options:
            awslogs-group: !Ref 'CloudwatchLogsGroup'
            awslogs-region: !Ref 'AWS::Region'
            awslogs-stream-prefix: ecs-gpu-demo-app
```
#### 3.6 Capacity Provider Association with ASG

A capacity provider must be associated with a cluster prior to being specified in a capacity provider strategy. So we have to associate the ARM and GPU based ECS Capacity providers with the ECS cluster. 

When multiple capacity providers are specified within a capacity provider strategy, at least one of the capacity providers must have a weight value greater than zero. Any capacity providers with a weight of `0` will not be used to place tasks. If you specify multiple capacity providers in a strategy that all have a weight of `0`, any `RunTask` or `CreateService` actions using the capacity provider strategy will fail.

By configuring Weight:1 for GPU Capacity provider, it will be default capacity provider for this ECS cluster. 

```yaml
#Associate ECS Cluster Capacity Provider with both the ARM and CPU capacity provider. 
  ClusterCPAssociation:
    Type: "AWS::ECS::ClusterCapacityProviderAssociations"
    Properties:
      Cluster: !Ref ECSCluster
      CapacityProviders:
        - !Ref ArmECSCapacityProvider
        - !Ref GpuECSCapacityProvider
      DefaultCapacityProviderStrategy:
        - Base: 0
          Weight: 0
          CapacityProvider: !Ref ArmECSCapacityProvider
        - Base: 0
          Weight: 1
          CapacityProvider: !Ref GpuECSCapacityProvider
```

As a part of the above CFN Stack creation, we are creating AWS Custom Resources to obtain both (ARM64 & GPU) the AutoScalingGroup ARNs. We also create the IAM resources: ECS Service Role, AutoScaling Group Service Role, Lambda Execution Role for custom resources and Instance Role for ECS container instances. 


The following is the output which shows successful creation of Cluster Resources in your account:

```bash
$ aws cloudformation describe-stacks --stack-name ecs-demo --query 'Stacks[*].Outputs' --output table
------------------------------------------------------------------------------------------------------------------------------
|                                                       DescribeStacks                                                       |
+------------------------+-------------------------+-------------------------------------------------------------------------+
|       Description      |        OutputKey        |                               OutputValue                               |
+------------------------+-------------------------+-------------------------------------------------------------------------+
|  ECS Cluster name      |  ecscluster             |  ecs-demo-ECSCluster-NPsCvf3k6aWv                                      |
|  Arm Capacity Provider |  ArmECSCapacityProvider |  ecs-demo-ArmECSCapacityProvider-FXpQH4EJ6DSz                          |
|  GPU Capacity Provicder|  GpuECSCapacityProvider |  ecs-demo-GpuECSCapacityProvider-KYleqfF16Iqy                          |
|  Arm64 task definition |  Armtaskdef             |  arn:aws:ecs:us-west-2:012345678912:task-definition/ecs-demo-arm64:3   |
|  GPU task definition   |  Gputaskdef             |  arn:aws:ecs:us-west-2:012345678912:task-definition/ecs-demo-gpu:2     |
+------------------------+-------------------------+-------------------------------------------------------------------------+
```

That’s it. We have deployed the base platform. Now, let’s move on to deploying ECS Tasks using desired task definitions in the shared ECS cluster. 