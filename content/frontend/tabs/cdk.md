---
title: "Acceptance and Production"
disableToc: true
hidden: true
---
 
## Validate deployment configuration

```bash
cd ~/environment/ecsdemo-frontend
```

#### Confirm that the cdk can synthesize the assembly CloudFormation templates 

```bash
cdk synth
```

#### Review what the cdk is proposing to build and/or change in the environment 

```bash
cdk diff
```

## Deploy the frontend web service
```bash
cdk deploy
```

## Code Review

As we mentioned in the platform build, we are defining our deployment configuration via code. Let's look through the code to better understand how cdk is deploying.

#### Importing base configuration values from our base platform stack

Because we built the platform in its own stack, there are certain environmental values that we will need to reuse amongst all services being deployed. In this custom construct, we are importing the VPC, ECS Cluster, and Cloud Map namespace from the base platform stack. By wrapping these into a custom construct, we are isolating the platform imports from our service deployment logic.

```python
class BasePlatform(core.Construct):
    
    def __init__(self, scope: core.Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        # The base platform stack is where the VPC was created, so all we need is the name to do a lookup and import it into this stack for use
        self.vpc = aws_ec2.Vpc.from_lookup(
            self, "ECSWorkshopVPC",
            vpc_name='ecsworkshop-base/BaseVPC'
        )
        
        # Importing the service discovery namespace from the base platform stack
        self.sd_namespace = aws_servicediscovery.PrivateDnsNamespace.from_private_dns_namespace_attributes(
            self, "SDNamespace",
            namespace_name=core.Fn.import_value('NSNAME'),
            namespace_arn=core.Fn.import_value('NSARN'),
            namespace_id=core.Fn.import_value('NSID')
        )
        
        # Importing the ECS cluster from the base platform stack
        self.ecs_cluster = aws_ecs.Cluster.from_cluster_attributes(
            self, "ECSCluster",
            cluster_name=core.Fn.import_value('ECSClusterName'),
            security_groups=[],
            vpc=self.vpc,
            default_cloud_map_namespace=self.sd_namespace
        )

        # Importing the security group that allows frontend to communicate with backend services
        self.services_sec_grp = aws_ec2.SecurityGroup.from_security_group_id(
            self, "ServicesSecGrp",
            security_group_id=core.Fn.import_value('ServicesSecGrp')
        )
```

#### Frontend service deployment code

For the frontend service, there are quite a few components that have to be built to serve it up as a frontend service. Those components are an Application Load Balancer, Target Group, ECS Task Definition, and an ECS Service. To build these components on our own would equate to hundreds of lines of CloudFormation, whereas with the higher level constructs that the cdk provides, we are able to build everything with 18 lines of code.

```python
class FrontendService(core.Stack):
    
    def __init__(self, scope: core.Stack, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        self.base_platform = BasePlatform(self, self.stack_name)

        # This defines some of the components required for the docker container to run
        self.fargate_task_image = aws_ecs_patterns.ApplicationLoadBalancedTaskImageOptions(
            image=aws_ecs.ContainerImage.from_registry("brentley/ecsdemo-frontend"),
            container_port=3000,
            environment={
                "CRYSTAL_URL": "http://ecsdemo-crystal.service:3000/crystal",
                "NODEJS_URL": "http://ecsdemo-nodejs.service:3000"
            },
        )

        # This high level construct will build everything required to ensure our container is load balanced and running as an ECS service
        self.fargate_load_balanced_service = aws_ecs_patterns.ApplicationLoadBalancedFargateService(
            self, "FrontendFargateLBService",
            cluster=self.base_platform.ecs_cluster,
            cpu=256,
            memory_limit_mib=512,
            desired_count=1,
            public_load_balancer=True,
            cloud_map_options=self.base_platform.sd_namespace,
            task_image_options=self.fargate_task_image
        )

        # Utilizing the connections method to connect the frontend service security group to the backend security group
        self.fargate_load_balanced_service.service.connections.allow_to(
            self.base_platform.services_sec_grp,
            port_range=aws_ec2.Port(protocol=aws_ec2.Protocol.TCP, string_representation="frontendtobackend", from_port=3000, to_port=3000)
        )
```

## Review service logs

#### Review the service logs from the command line:

{{%expand "Expand here to see the solution" %}}

- First, because the cdk created a log group on our behalf, we need to get the name of the service. Next, using an open source tool awslogs, we will 

```bash
log_group=$(awslogs groups -p ecsworkshop-frontend)
awslogs get -G -S --timestamp --start 1m --watch $log_group
```

- Here is an example of what the output would look like:

![clilogs](/images/cli-logs.gif)

{{% /expand %}}

#### Review the service logs from the console:

{{%expand "Expand here to see the solution" %}}

- First, we will navigate to ECS in the console and drill down into our service to get detailed information. As you can see, there is a lot of information that we can gather around the service itself, such as Load Balancer details, number of tasks running, as well as logs. Click the logs tab to review the logs for the running service.
![Console2ServiceLogs](/images/ecs-console-service-logs.gif)

- Next, we can review our service logs in near real time. You can go back in time as far as one week, or drill down to the past 30 seconds. In the example below, we select 30 seconds.
![ConsoleServiceLogs](/images/ecs-console-logs.gif)

{{% /expand %}}

## Scale the service

#### Manually scaling
{{%expand "Expand here to see the solution" %}}

- To manually scale the service up, we simply will modify the code in `app.py` and change the desired count from 1 to 3

```python
self.fargate_load_balanced_service = aws_ecs_patterns.ApplicationLoadBalancedFargateService(
    self, "FrontendFargateLBService",
    cluster=self.base_platform.ecs_cluster,
    cpu=256,
    memory_limit_mib=512,
    desired_count=3,
    #desired_count=1,
    public_load_balancer=True,
    cloud_map_options=self.base_platform.sd_namespace,
    task_image_options=self.fargate_task_image
)
```

- Once you have updated the code, let's validate that the changes will take effect.

```bash
cdk diff
```

- The output should look like this:

![diff-service-count](/images/cdk-service-count-diff.png)

- Now that we've confirmed the changes look good, let's deploy them.

```bash
cdk deploy
```

- The output should look something like this:

![update-service-count](/images/cdk-deploy-service-count.png)

{{% /expand %}}

#### Autoscaling
{{%expand "Expand here to see the solution" %}}

- Coming soon!

{{% /expand %}}
