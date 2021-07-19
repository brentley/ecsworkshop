+++
title = "Deploy sample application"
chapter = false
weight = 8
+++

In this chapter we will enable Prometheus metrics collection from an ECS cluster. In this scenario, we will use the Prometheus Receiver to scrape from application and the AWS ECS Container Metrics Receiver to scrape infrastructure metrics.

We will deploy sample app which has ADOT Collector and a Prometheus metric emitter.

Our ADOT Collector configuration will contain two pipelines:

- To scrape application metrics, we will configure the Prometheus Receiver to scrape application metrics from static hosts and export our metrics using the AWS Prometheus Remote Write Exporter.
- To scrape Amazon ECS Metrics, we will configure the AWS ECS Container Metrics Receiver to collect ECS metrics and another AWS Prometheus Remote Write Exporter to export metrics.


In the Cloud9 workspace, run the following commands:


#### Set environment variables to get AMP Remote Write Endpoint created in previous step and add it to ADOT config file

```bash
cd ~/environment/ecsdemo-amp/cdk

export AMP_WORKSPACE_ID=$(aws amp list-workspaces --query 'workspaces[*].workspaceId' --output text)
export AMP_Prometheus_Endpoint=$(aws amp describe-workspace --workspace-id $AMP_WORKSPACE_ID --query 'workspace.prometheusEndpoint' --output text)
export AMP_Prometheus_Remote_Write_Endpoint='"'${AMP_Prometheus_Endpoint}api/v1/remote_write'"'

sed -i -e "s~{{endpoint}}~$AMP_Prometheus_Remote_Write_Endpoint~" ecs-fargate-adot-config.yaml
sed -i -e "s~{{region}}~$AWS_REGION~" ecs-fargate-adot-config.yaml
```


#### Confirm that the cdk can synthesize the assembly CloudFormation templates

```bash
cdk synth
```

#### Review what the cdk is proposing to build and/or change in the environment

```bash
cdk diff
```

## Deploy sample application
```bash
cdk deploy --require-approval never
```

## Code Review


#### Prometheus sample application deployment code

For the Prometheus sample application, we simply want to run containers from a docker images, but still need to figure out how to deploy it and get it behind a scheduler. To do this on our own, we would need to build a VPC, ECS cluster, Task definition and ECS service. To build these components on our own would equate to hundreds of lines of CloudFormation, whereas with the higher level constructs that the cdk provides, we are able to build everything with 80 lines of code.

```python
class AmpService(cdk.Stack):

    def __init__(self, scope: cdk.Stack, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        # This construct builds Amazon VPC
        self.vpc = ec2.Vpc(self, "VPC")

        # This construct creates Amazon ECS cluster in previously built Amazon VPC
        self.ecs_cluster = ecs.Cluster(self, "DemoCluster", vpc=self.vpc)

        # Reading ADOT Collector configuration file
        with open("ecs-fargate-adot-config.yaml", 'r') as f:
            adot_config = f.read()

        # Amazon ECS Fargate Task Definition
        self.fargate_task_def = ecs.TaskDefinition(
            self, "aws-otel-FargateTask",
            compatibility=ecs.Compatibility.EC2_AND_FARGATE,
            cpu='256',
            memory_mib='1024'
        )

        # Creating Amazon CloudWatch Log groups and setting them to be deleted upon stack removal
        self.adot_log_grp = logs.LogGroup(
            self, "AdotLogGroup",
            removal_policy=cdk.RemovalPolicy.DESTROY
        )

        self.app_log_grp = logs.LogGroup(
            self, "AppLogGroup",
            removal_policy=cdk.RemovalPolicy.DESTROY
        )
        # ADOT Collector container configuration. Here we pull container image from Public Amazon ECR repository
        self.otel_container = self.fargate_task_def.add_container(
            "aws-otel-collector",
            image=ecs.ContainerImage.from_registry("public.ecr.aws/aws-observability/aws-otel-collector:latest"),
            memory_reservation_mib=512,
            logging=ecs.LogDriver.aws_logs(
                stream_prefix='/ecs/ecs-aws-otel-sidecar-collector-cdk',
                log_group=self.adot_log_grp
            ),
            environment={
                "REGION": getenv('AWS_REGION'),
                "AOT_CONFIG_CONTENT": adot_config
            },
        )
        # Sample Prometheus metric emitter container configuration. Here we build image from Docker file and push it to Amazon ECR repository
        self.prom_container = self.fargate_task_def.add_container(
            "prometheus-sample-app",
            image=ecs.ContainerImage.from_docker_image_asset(
                asset=ecr_a.DockerImageAsset(
                    self, "PromAppImage",
                    directory='../prometheus'
                )
            ),
            memory_reservation_mib=256,
            logging=ecs.LogDriver.aws_logs(
                stream_prefix='/ecs/prometheus-sample-app-cdk',
                log_group=self.app_log_grp
            ),
            environment={
                "REGION": getenv('AWS_REGION')
            },
        )
        # Amazon ECS Service Definition
        self.fargate_service = ecs.FargateService(
            self, "AmpFargateService",
            service_name='aws-otel-FargateService',
            task_definition=self.fargate_task_def,
            cluster=self.ecs_cluster,
            desired_count=1,
        )
        # Here we add required IAM permissions for Amazon ECS Task Role
        self.fargate_task_def.add_to_task_role_policy(
            iam.PolicyStatement(
                actions=[
                    "logs:PutLogEvents",
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:DescribeLogStreams",
                    "logs:DescribeLogGroups",
                    "ssm:GetParameters",
                    "aps:RemoteWrite"
                ],
                resources=['*']
            )
        )
```