---
title: Deploy the environment and tasks
chapter: false
weight: 20
---

#### 3. Clone the repository

```bash
cd ~/environment
git clone https://github.com/aws-containers/ecsworkshop-advanced-scheduling-chapter.git
cd ecsworkshop-advanced-scheduling-chapter
```

We are defining our deployment configuration via code using AWS Cloudformation. Let’s look through the code to better understand what resources CloudFormation will create. 

#### 3.2 Deploying Networking CFN Stack:

To start, we will deploy standard networking resources (VPC, Public and Private Subnets) using the following AWS CloudFormation (CFN) template, naming the stack as `ecsworkshop-vpc`:

```bash
aws cloudformation create-stack \
  --stack-name=ecsworkshop-vpc \
  file://ecsworkshop-vpc.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

Once the above CFN stack is ready (reached CREATE_COMPLETE state), the stack will export values namely `VPCId`, `SecurityGroup` , `Public & Private SubnetIds`. We will need these values when creating the EC2 instances. 
Run the following aws cli command which calls the `DescribeStack` API, and verifies the creation of networking resources:

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

If you see the above output, you're ready to move on to the next step.

#### 3.3 Deploying the Cluster Resources:

Next we will create the ECS Cluster infrastructure, which we'll dive into in more detail below. In this stack deployment, we are importing the VPC, Security Group, and Subnets from the VPC base platform stack that we deployed above. 

```bash
aws cloudformation create-stack \
    --stack-name=ecs-demo \
    --template-body=ecsworkshop-demo.yaml \
    --capabilities CAPABILITY_NAMED_IAM
```

The above command deploys a Cloudformation stack that contains the following AWS resources: an ECS Cluster, Launch Configurations, AutoScaling Groups that point to the ECS optimized AMI's. 
There are two AutoScaling Groups that we create: One that is ARM based, and the other that has GPU's attached.

While the deployment is ongoing, let's review the Cloudformation template to better understand what we are deploying.

### Code Review

As mentioned earlier, the goal of this chapter in the workshop is to schedule tasks onto EC2 instances that match their corresponding requirements. 
This two use cases we're working with are to deploy ARM based containers as well as containers that require GPU's.
Let's start with reviewing the ARM infrastructure.

#### 3.4 ARM Cluster Capacity and Task Definition

To deploy ARM based EC2 instances to our cluster, we need to create some resources that will get our ARM based EC2 instances up and running and connected to the cluster. 

We start with creating our launch configuration, which is where we specify the AMI ID, security group and IAM role details, and finally the user data which runs the code we defined inline.
The code in the user data will register the EC2 instance to the cluster.

```yaml
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
```

Next, we will create an Autoscaling group which contains a collection of Amazon EC2 instances that are treated as a logical grouping for the purposes of automatic scaling and management. 
An Auto Scaling group also enables you to use Amazon EC2 Auto Scaling features such as health check replacements and scaling policies. 
```yaml
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
```

For scaling and management of the Autoscaling group, we create a capacity provider with cluster autoscaling enabled. 
This will ensure that as tasks are launched, EC2 instances come up and down as needed.
We associate the capacity provider with the Autoscaling group we created above, which in turn will be controlled by ECS as scaling is needed.

```yaml
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

Finally we deploy our task definition, which instructs Amazon ECS as to how we want to launch our containers.
In this task definition we define our container image, cpu/memory requirements, logging configuration, as well as the placement constraints.
The placement constraints directive is where we have more control over where the tasks land when launched.
With ECS there are two types of constraints that can be used: 

1) distinctInstance
    - Place each task on a different container instance. This task placement constraint can be specified when either running a task or creating a new service.

2) memberOf
    - Place tasks on container instances that satisfy an expression. For more information about the expression syntax for constraints, see (Cluster query language)[https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html].

In the task definition below we are using the `memberOf` constraint with an expression querying the default (attribute)[https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes] of `cpu-architecture`.
Using the Cluster query language, we are instructing ECS to schedule these tasks only onto EC2 instances that are arm64 architecture. 

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

#### 3.5 GPU Cluster Capacity and Task Definition

Similar to how we defined our resources above, we do the same for GPU enabled instances. 
The main difference here is the AMI used.

```yaml
  GpuASGLaunchConfiguration:
    Type: AWS::AutoScaling::LaunchConfiguration
    Properties:
      ImageId: !Ref GPULatestAmiId
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

In the below task definition we define our container image that requires GPU to run. 
Like the ARM task, we use the `memberOf` placement constraint but the query is a little different.
Here we are placing these tasks based off of instance-type, as our tasks can not run without GPU's available.
We could also create a custom attribute and query off of that just in case we wanted to use multiple instance types.

Also you may notice that the container is requesting a GPU under the `ResourceRequirements` key. 
This will ensure that a GPU is assigned to the task when launched.

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

### Confirm resources are deployed

Run the following to get the output which shows the cluster resources in your account:

```bash
$ aws cloudformation describe-stacks --stack-name ecs-demo --query 'Stacks[*].Outputs' --output table
```

The output should look like this:

```
------------------------------------------------------------------------------------------------------------------------------
|                                                       DescribeStacks                                                       |
+------------------------+-------------------------+-------------------------------------------------------------------------+
|       Description      |        OutputKey        |                               OutputValue                               |
+------------------------+-------------------------+-------------------------------------------------------------------------+
|  ECS Cluster name      |  ecscluster             |  ecs-demo-ECSCluster-NPsCvf3k6aWv                                      |
|  Arm Capacity Provider |  ArmECSCapacityProvider |  ecs-demo-ArmECSCapacityProvider-FXpQH4EJ6DSz                          |
|  GPU Capacity Provicder|  GpuECSCapacityProvider |  ecs-demo-GpuECSCapacityProvider-KYleqfF16Iqy                          |
|  Arm64 task definition |  Armtaskdef             |  arn:aws:ecs:us-west-2:012345678912:task-definition/ecs-demo-arm64:1   |
|  GPU task definition   |  Gputaskdef             |  arn:aws:ecs:us-west-2:012345678912:task-definition/ecs-demo-gpu:1     |
+------------------------+-------------------------+-------------------------------------------------------------------------+
```

At this point we have deployed the base platform and are ready to run some containers. Let’s move on to deploying ECS tasks using desired task definitions in the shared ECS cluster. 