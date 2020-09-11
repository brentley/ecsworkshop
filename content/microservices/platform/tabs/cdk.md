---
title: "Acceptance and Production"
disableToc: true
hidden: true
---

 
#### Navigate to the platform repo
```bash
cd ~/environment/container-demo/cdk
```
#### Confirm that the cdk can synthesize the assembly CloudFormation templates 
```bash
cdk synth
```

{{%expand "Fun exercise! Let's count the total number of lines to compare the code written in cdk vs the total lines of generated as CloudFormation. Expand here to see the solution" %}}

```bash
echo -e "Cloudformation Lines==$(cdk synth |wc -l)\nCDK Lines==$(cat app.py|wc -l)"
```

- The end result should look something like this:

```bash
Cloudformation Lines==470
CDK Lines==82
```

{{% /expand %}}

#### View proposed changes to the environment
```bash
cdk diff
```

#### Deploy the changes to the environment
```bash
cdk deploy --require-approval never
```

Let's take a look at what's being built. You may notice that everything defined in the stack is 100% written as python code. We also benefit from the opinionated nature of cdk by letting it build out components based on well architected practices. This also means that we don't have to think about all of the underlying components to create and connect resources (ie, subnets, nat gateways, etc). Once we deploy the cdk code, the cdk will generate the underlying Cloudformation templates and deploy it.

```python
# This resource alone will create a private/public subnet in each AZ as well as nat/internet gateway(s)
self.vpc = aws_ec2.Vpc(
    self, "BaseVPC",
    cidr='10.0.0.0/24',
)

# Creating ECS Cluster in the VPC created above
self.ecs_cluster = aws_ecs.Cluster(
    self, "ECSCluster",
    vpc=self.vpc
)

# Adding service discovery namespace to cluster
self.ecs_cluster.add_default_cloud_map_namespace(
    name="service",
)

# Frontend security group frontend service to backend services
self.services_3000_sec_group = aws_ec2.SecurityGroup(
    self, "FrontendToBackendSecurityGroup",
    allow_all_outbound=True,
    description="Security group for frontend service to talk to backend services",
    vpc=self.vpc
)

# Allow inbound 3000 from ALB to Frontend Service
self.sec_grp_ingress_self_3000 = aws_ec2.CfnSecurityGroupIngress(
    self, "InboundSecGrp3000",
    ip_protocol='TCP',
    source_security_group_id=self.services_3000_sec_group.security_group_id,
    from_port=3000,
    to_port=3000,
    group_id=self.services_3000_sec_group.security_group_id
)

##CREATING TEMPORARY EC2 INSTANCE TO LOAD TEST NODEJS AND CRYSTAL SERVICES##
# Pulling latest AMI that will be used to create the ec2 instance
amzn_linux = aws_ec2.MachineImage.latest_amazon_linux(
    generation=aws_ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
    edition=aws_ec2.AmazonLinuxEdition.STANDARD,
    virtualization=aws_ec2.AmazonLinuxVirt.HVM,
    storage=aws_ec2.AmazonLinuxStorage.GENERAL_PURPOSE
    )

# Instance Role/profile that will be attached to the ec2 instance 
# Enabling service role so the EC2 service can use ssm
role = aws_iam.Role(self, "InstanceSSM", assumed_by=aws_iam.ServicePrincipal("ec2.amazonaws.com"))

# Attaching the SSM policy to the role so we can use SSM to ssh into the ec2 instance
role.add_managed_policy(aws_iam.ManagedPolicy.from_aws_managed_policy_name("service-role/AmazonEC2RoleforSSM"))


# Reading user data, to install siege into the ec2 instance.
with open("stresstool_user_data.sh") as f:
    user_data = f.read()

# Instance creation
self.instance = aws_ec2.Instance(self, "Instance",
    instance_name="{}-stresstool".format(stack_name),
    instance_type=aws_ec2.InstanceType("t3.medium"),
    machine_image=amzn_linux,
    vpc = self.vpc,
    role = role,
    user_data=aws_ec2.UserData.custom(user_data),
    security_group=self.services_3000_sec_group
        )


# All Outputs required for other stacks to build
core.CfnOutput(self, "NSArn", value=self.namespace_outputs['ARN'], export_name="NSARN")
core.CfnOutput(self, "NSName", value=self.namespace_outputs['NAME'], export_name="NSNAME")
core.CfnOutput(self, "NSId", value=self.namespace_outputs['ID'], export_name="NSID")
core.CfnOutput(self, "FE2BESecGrp", value=self.services_3000_sec_group.security_group_id, export_name="SecGrpId")
core.CfnOutput(self, "ECSClusterName", value=self.cluster_outputs['NAME'], export_name="ECSClusterName")
core.CfnOutput(self, "ECSClusterSecGrp", value=self.cluster_outputs['SECGRPS'], export_name="ECSSecGrpList")
core.CfnOutput(self, "ServicesSecGrp", value=self.services_3000_sec_group.security_group_id, export_name="ServicesSecGrp")
core.CfnOutput(self, "StressToolEc2Id",value=self.instance.instance_id)
core.CfnOutput(self, "StressToolEc2Ip",value=self.instance.instance_private_ip)
```

When the stack is done building, it will print out all of the outputs for the underlying CloudFormation stack. These outputs are what we use to reference the base platform when deploying the microservices. Below is an example of what the outputs look like:

```bash
    ecsworkshop-base

Outputs:
ecsworkshop-base.NSName = service
ecsworkshop-base.StressToolEc2Ip = 10.0.0.100
ecsworkshop-base.NSId = ns-6ao4bo7j4atvqt6d
ecsworkshop-base.ECSClusterName = container-demo
ecsworkshop-base.FE2BESecGrp = sg-022215fe3d238e192
ecsworkshop-base.NSArn = arn:aws:servicediscovery:us-west-2:875448814018:namespace/ns-6ao4bo7j4atvqt6d
ecsworkshop-base.ServicesSecGrp = sg-022215fe3d238e192
ecsworkshop-base.ECSClusterSecGrp = []
ecsworkshop-base.StressToolEc2Id = i-04908250956954470

Stack ARN:
arn:aws:cloudformation:us-west-2:875448814018:stack/ecsworkshop-base/62614260-f22e-11ea-8d70-061326aceaf4
```

That's it, we have deployed the base platform. Now let's move on to deploying the microservices.
