+++
title = "Build Environment"
chapter = false
weight = 3
+++

#### Install prerequisites

```bash
sudo yum install -y jq
npm i -g -f aws-cdk@1.54.0
```

#### Navigate to the repo

```bash
git clone https://github.com/adamjkeller/ecs-codepipeline-demo ~/environment/ecs-codepipeline-demo
cd ~/environment/ecs-codepipeline-demo
```

#### Build the stack

```bash
npm install
npm run build
```

#### Bootstrap CDK 

**This creates an S3 bucket that holds the file assets and the resulting CloudFormation template to deploy.**

```bash
cdk bootstrap
```

#### Code Review
Similar to the previous environments, we follow the same format to build the environment using AWS CDK.

{{%expand "Let's Dive in" %}}

* Create the ECR and CodeCommit repositories

```typescript
// ECR repository for the docker images
const ecrRepo = new ecr.Repository(this, 'demoAppEcrRepo', {
    imageScanOnPush: true
});

// CodeCommit repository for storing the source code
const codeRepo = new codeCommit.Repository(this, "demoAppCodeRepo", {
    repositoryName: BlueGreenUsingEcsStack.ECS_APP_NAME,
    description: "Demo application hosted on NGINX"
});
```

* Create the CodeBuild project. We provide the ENVIRONMENT variables needed during the build phase. These variables are used for updating the `buildspec.yml`,`taskdef.json` and `appspec.yaml`. We will take a look at these configuration files after the stack is built.

```typescript
// Creating the code build project
const demoAppCodeBuild = new codeBuild.Project(this, "demoAppCodeBuild", {
    role: codeBuildServiceRole,
    description: "Code build project for the demo application",
    environment: {
        buildImage: codeBuild.LinuxBuildImage.STANDARD_4_0,
        computeType: ComputeType.SMALL,
        privileged: true,
        environmentVariables: {
            REPOSITORY_URI: {
                value: ecrRepo.repositoryUri,
                type: BuildEnvironmentVariableType.PLAINTEXT
            },
            TASK_EXECUTION_ARN: {
                value: ecsTaskRole.roleArn,
                type: BuildEnvironmentVariableType.PLAINTEXT
            },
            TASK_FAMILY: {
                value: BlueGreenUsingEcsStack.ECS_TASK_FAMILY_NAME,
                type: BuildEnvironmentVariableType.PLAINTEXT
            }
        }
    },
    source: codeBuild.Source.codeCommit({
        repository: codeRepo
    })
});
```

* Create the ECS cluster with application load balancer and target groups. We have two target groups - blue and green. The production listener port is `80` and the test listener port is `8080`

```typescript
// Creating the VPC
const vpc = new ec2.Vpc(this, 'vpcForECSCluster');

// Creating a ECS cluster
const cluster = new ecs.Cluster(this, 'ecsClusterForWorkshop', {vpc});

// Creating an application load balancer, listener and two target groups for Blue/Green deployment
const alb = new elb.ApplicationLoadBalancer(this, "alb", {
    vpc: vpc,
    internetFacing: true
});
const albProdListener = alb.addListener('albProdListener', {
    port: 80
});
const albTestListener = alb.addListener('albTestListener', {
    port: 8080
});

albProdListener.connections.allowDefaultPortFromAnyIpv4('Allow traffic from everywhere');
albTestListener.connections.allowDefaultPortFromAnyIpv4('Allow traffic from everywhere');

// Target group 1
const blueGroup = new elb.ApplicationTargetGroup(this, "blueGroup", {
    vpc: vpc,
    protocol: ApplicationProtocol.HTTP,
    port: 80,
    targetType: TargetType.IP,
    healthCheck: {
        path: "/",
        timeout: Duration.seconds(10),
        interval: Duration.seconds(15)
    }
});

// Target group 2
const greenGroup = new elb.ApplicationTargetGroup(this, "greenGroup", {
    vpc: vpc,
    protocol: ApplicationProtocol.HTTP,
    port: 80,
    targetType: TargetType.IP,
    healthCheck: {
        path: "/",
        timeout: Duration.seconds(10),
        interval: Duration.seconds(15)
    }
});

// Registering the blue target group with the production listener of load balancer
albProdListener.addTargetGroups("blueTarget", {
    targetGroups: [blueGroup]
});

// Registering the green target group with the test listener of load balancer
albTestListener.addTargetGroups("greenTarget", {
    targetGroups: [greenGroup]
});
```

* For DeploymentGroup of the CodeDeploy, we have used a custom resource. The CDK construct does not support creating a ECS deployment group. First we create the lambda using the `new lambda.Function`, then we create the custom resource using `new CustomResource`

```typescript
// Creating the code deploy application
const codeDeployApplication = new codeDeploy.EcsApplication(this, "demoAppCodeDeploy");

// Custom resource to create the deployment group
const createDeploymentGroupLambda = new lambda.Function(this, 'createDeploymentGroupLambda', {
    code: lambda.Code.fromAsset(
        path.join(__dirname, 'custom_resources'),
        {
            exclude: ["**", "!create_deployment_group.py"]
        }),
    runtime: lambda.Runtime.PYTHON_3_8,
    handler: 'create_deployment_group.handler',
    role: customLambdaServiceRole,
    description: "Custom resource to create deployment group",
    memorySize: 128,
    timeout: cdk.Duration.seconds(60)
});

new CustomResource(this, 'customEcsDeploymentGroup', {
    serviceToken: createDeploymentGroupLambda.functionArn,
    properties: {
        ApplicationName: codeDeployApplication.applicationName,
        DeploymentGroupName: BlueGreenUsingEcsStack.ECS_DEPLOYMENT_GROUP_NAME,
        DeploymentConfigName: BlueGreenUsingEcsStack.ECS_DEPLOYMENT_CONFIG_NAME,
        ServiceRoleArn: codeDeployServiceRole.roleArn,
        BlueTargetGroup: blueGroup.targetGroupName,
        GreenTargetGroup: greenGroup.targetGroupName,
        ProdListenerArn: albProdListener.listenerArn,
        TestListenerArn: albTestListener.listenerArn,
        EcsClusterName: cluster.clusterName,
        EcsServiceName: demoAppService.serviceName,
        TerminationWaitTime: BlueGreenUsingEcsStack.ECS_TASKSET_TERMINATION_WAIT_TIME,
        BlueGroupAlarm: blueGroupAlarm.alarmName,
        GreenGroupAlarm: greenGroupAlarm.alarmName,
    }
});

```

* Code pipeline for the blue/green deployment. This pipeline has three stages - Source, Build and Deploy

```typescript

// Code Pipeline - CloudWatch trigger event is created by CDK
new codePipeline.Pipeline(this, "ecsBlueGreen", {
    role: codePipelineServiceRole,
    artifactBucket: demoAppArtifactsBucket,
    stages: [
        {
            stageName: 'Source',
            actions: [
                new codePipelineActions.CodeCommitSourceAction({
                    actionName: 'Source',
                    repository: codeRepo,
                    output: sourceArtifact,
                }),
            ]
        },
        {
            stageName: 'Build',
            actions: [
                new codePipelineActions.CodeBuildAction({
                    actionName: 'Build',
                    project: demoAppCodeBuild,
                    input: sourceArtifact,
                    outputs: [buildArtifact]
                })
            ]
        },
        {
            stageName: 'Deploy',
            actions: [
                new codePipelineActions.CodeDeployEcsDeployAction({
                    actionName: 'Deploy',
                    deploymentGroup: ecsDeploymentGroup,
                    appSpecTemplateInput: buildArtifact,
                    taskDefinitionTemplateInput: buildArtifact,
                })
            ]
        }
    ]
});

```




{{% /expand %}}

#### Synthesize the CloudFormation templates

```bash
cdk synth
```

#### Review what the cdk is proposing to build and/or change in the environment

```bash
cdk diff
```

#### Deploy the resources

* **Note:**
    * The stack will create a new VPC with CIDR `10.0.0.0/16`
    * The stack will create a new CodeCommit repository named `demo-app`

```bash
cdk deploy --require-approval never
```

* A successful deployment will output the below values
    * `BlueGreenUsingEcsStack.ecsBlueGreenLBDns`
    * `BlueGreenUsingEcsStack.ecsBlueGreenCodeRepo`

#### Exporting the Load Balancer URL

```bash
export cloudformation_outputs=$(aws cloudformation describe-stacks --stack-name BlueGreenUsingEcsStack | jq '.Stacks[].Outputs')
export load_balancer_url=$(echo $cloudformation_outputs | jq -r '.[]| select(.ExportName | contains("ecsBlueGreenLBDns"))| .OutputValue')
```

* Let's see the deployed version of the application
