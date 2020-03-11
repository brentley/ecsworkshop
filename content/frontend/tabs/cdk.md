---
title: "Acceptance and Production"
disableToc: true
hidden: true
---
 
## Validate deployment configuration

```bash
cd ~/environment/ecsdemo-frontend/cdk
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
cdk deploy --require-approval never
```

- Once the deployment is complete, there will be two outputs. Look for the frontend url output, and open that link in a new tab. At this point you should see the frontend website up and running. Below is an example output:

![feoutput](/images/frontend-output.png)

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

- First, because the cdk created a log group on our behalf, we need to get the name of the log-group based on the name of the service. Next, we will tail the active logs from CloudWatch in the terminal. We achieve this by using an open source tool called [awslogs](https://github.com/jorgebastida/awslogs).

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

#### Why autoscale?

- Well, to put it simply - it's either a human scales the service, or the orchestrator. 
    - If we choose to do it manually, this means that as load increases, we need to stop what we are doing to scale the service to meet the load (and not to mention that we have to eventually scale back down once the load clears). This can be tedious and painful, hence why autoscaling exists.
    - If we let the orchestrator handle the scaling in and out for the service, we can focus on continuous improvement, and less on operational heavy lifting. In order to get autoscaling setup, one first needs to know what metric to use as the decision to autoscale. Some example metrics for scaling are CPU utilization, memory utilization, and queue depth.

#### Setup Autoscaling in the code

- Using the editor of your choice, open app.py in the cdk directory.

- Search for `Enable Service Autoscaling` to find the code that will enable autoscaling for the service.

- Remove the comments (#) from the code for self.autoscale and below, once you remove them, it should look like the following:

```python
# Enable Service Autoscaling
self.autoscale = self.fargate_load_balanced_service.service.auto_scale_task_count(
    min_capacity=1,
    max_capacity=10
)

self.autoscale.scale_on_cpu_utilization(
    "CPUAutoscaling",
    target_utilization_percent=50,
    scale_in_cooldown=core.Duration.seconds(30),
    scale_out_cooldown=core.Duration.seconds(30)
)
```

#### Code Review

- To start modeling our autoscaling logic, we first set what our upper and lower bounds are. This ensures that we will always be at a minimum of 1 task, and a maximum of 10 tasks.

```python
# Enable Service Autoscaling
self.autoscale = self.fargate_load_balanced_service.service.auto_scale_task_count(
    min_capacity=1,
    max_capacity=10
)
```

- When the ECS service is deployed, Cloudwatch metrics such as CPU utilization are enabled by default. We are going to take advantage of that metric and use it as our scaling target. In this method, we are setting what our target cpu utilization percent is, and how long in between scale activities we want to wait before it adds/removes another task.

```python
self.autoscale.scale_on_cpu_utilization(
    "CPUAutoscaling",
    target_utilization_percent=50,
    scale_in_cooldown=core.Duration.seconds(30),
    scale_out_cooldown=core.Duration.seconds(30)
)
```

#### Deploy Autoscaling

- Now that you have the autoscaling code in place, let's deploy it!

- Let's see a diff of our present state, vs the proposed changes to our environment. Run the following:

```bash
cdk diff
```

- You should see the additon of two resources (image below). ECS is utilizing the Application Autoscaling service to manage the scaling of ECS tasks. In short, this will create a [target tracking policy](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-autoscaling-targettracking.html), which will set the desired target for scaling in and out (in this case, CPU utilization), and attach it to the ECS service.

![task-as](/images/task-autoscaling-example.png)

- Deploy time!

```bash
cdk deploy --require-approval never
```

#### Load test

- Next, let's generate some load on the frontend. 

```bash
alb_url=$(aws cloudformation describe-stacks --stack-name ecsworkshop-frontend --query "Stacks" --output json | jq -r '.[].Outputs[] | select(.OutputKey |contains("LoadBalancer")) | .OutputValue')
siege -c 20 -i $alb_url&
```

- While siege is running in the background, either navigate to the console or monitor the autoscaling from the command line.

{{%expand "Command Line" %}}

- Compare the tasks running vs tasks desired. As the load increases on the frontend service, we should see these counts eventually increase up to 10. This is autoscaling happening in real time. Please note that this step will take a few minutes. Feel free to run this in one terminal, and move on to the next steps in another terminal.

```bash
while true; do sleep 3; aws ecs describe-services --cluster container-demo --services ecsdemo-frontend | jq '.services[] | "Tasks Desired: \(.desiredCount) vs Tasks Running: \(.runningCount)"'; done 
```

- Now that we've seen the service autoscale out, let's stop the running while loop. Simply press `control + c` to cancel.

- Time to cancel the load test. By prepending our command with `&`, we instructed it to run in the background. Bring it back to the foreground, and stop it. To stop it, type the following:

    - `fg`
    - `control + c`

- NOTE: To ensure application availability, the service scales out proportionally to the metric as fast as it can, but scales in more gradually. For more information, see the [documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-autoscaling-targettracking.html)

{{% /expand %}}

{{%expand "Console" %}}
- Coming soon!
{{% /expand %}}

{{% /expand %}}
