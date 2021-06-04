---
title: "Acceptance and Production"
disableToc: true
hidden: true
---
 
#### Build the environment

The first step in the workshop is to deploy our application running on Amazon EC2.
Run the commands below and while the build is happening, proceed to the code review section to gain an understanding of what we're building and deploying.

```bash
cd ~/environment/ec2_to_ecs_migration_workshop/build_ec2_environment
cdk deploy --require-approval never
```
 
 
#### Code Review

Similar to how we deployed in all of the other environments, we follow the same format here by using the AWS CDK. The only difference is that we will deploy the ECS task definition and service using the AWS CLI. 
We're going to skip over some items that we've gone over previously in the workshop (importing the existing vpc, and ecs cluster for example).

{{%expand "Let's Dive in" %}}

The ECS service we are going to deploy relies on an Application Load Balancer that serves traffic on port 80. The route back to the container will be on port 8000.
We will also create a security group allowing all inbound traffic on port 80 to the load balancer.

```python
## Load balancer for ECS service ##
self.frontend_sec_grp = ec2.SecurityGroup(
    self, "FrontendIngress",
    vpc=self.vpc,
    allow_all_outbound=True,
    description="Frontend Ingress All port 80",
)

self.load_balancer = elbv2.ApplicationLoadBalancer(
    self, "ALB",
    security_group=self.frontend_sec_grp,
    internet_facing=True,
    vpc=self.vpc
)
```

We need a way for the load balancer to talk back to our ECS Fargate service. This is done via a Target Group and attaching that Target Group to a listener on the load balancer.
The Target Group is important here as the ECS orchestrator will dynamically add and remove tasks from the Target Group as needed.

```python
self.target_group = elbv2.ApplicationTargetGroup(
    self, "ALBTG",
    port=8000,
    target_group_name="ECSDemoFargateEFS",
    vpc=self.vpc,
    target_type=elbv2.TargetType.IP
)

self.load_balancer.add_listener(
    "FrontendListener",
    default_target_groups=[
        self.target_group
    ],
    port=80
)
## End Load balancer ##
```

The main goal of this portion of the workshop is to persist data outside of the life of the containers, and this is where we create the EFS Volumes.
There are quite a few things being done here. At a high level, we are creating a security group to allow the service to receive traffic on port 8000, as well as communicate with the EFS mounts over port 2049 (NFS).
Lastly, we create the EFS filesystem with the security group attached to ensure the service can communicate back into the EFS file share.

```python
## EFS Setup ##
self.service_sec_grp = ec2.SecurityGroup(
    self, "EFSSecGrp",
    vpc=self.vpc,
    description="Allow access to self on NFS Port",
)

self.service_sec_grp.connections.allow_from(
    other=self.service_sec_grp,
    port_range=ec2.Port(protocol=ec2.Protocol.TCP, string_representation="Self", from_port=2049, to_port=2049)
)

self.service_sec_grp.connections.allow_from(
    other=self.frontend_sec_grp,
    port_range=ec2.Port(protocol=ec2.Protocol.TCP, string_representation="LB2Service", from_port=8000, to_port=8000)
)

self.shared_fs = efs.EfsFileSystem(
    self, "SharedFS",
    vpc=self.vpc,
    security_group=self.service_sec_grp,
)
## End EFS Setup ##

# Task execution role
self.task_execution_role = iam.Role(
    self, "TaskExecutionRole",
    assumed_by=iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
    description="Task execution role for ecs services",
    managed_policies=[
        iam.ManagedPolicy.from_managed_policy_arn(self, 'arn', managed_policy_arn='arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy')
    ]
)

## END IAM ##
```
{{% /expand %}}

#### Confirm that the cdk can synthesize the assembly CloudFormation templates 

```bash
cdk synth
```

#### Review what the cdk is proposing to build and/or change in the environment 

```bash
cdk diff
```

#### Deploy the resources
```bash
cdk deploy --require-approval never
```

- Once the deployment is complete, it's time to move to the next step where we will deploy the actual container as a service.
