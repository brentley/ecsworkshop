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
Cloudformation Lines==468
CDK Lines==81
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

# All Outputs required for other stacks to build in the same environment
core.CfnOutput(self, "NSArn", value=self.namespace_outputs['ARN'], export_name="NSARN")
core.CfnOutput(self, "NSName", value=self.namespace_outputs['NAME'], export_name="NSNAME")
core.CfnOutput(self, "NSId", value=self.namespace_outputs['ID'], export_name="NSID")
core.CfnOutput(self, "FE2BESecGrp", value=self.services_3000_sec_group.security_group_id, export_name="SecGrpId")
core.CfnOutput(self, "ECSClusterName", value=self.cluster_outputs['NAME'], export_name="ECSClusterName")
core.CfnOutput(self, "ECSClusterSecGrp", value=self.cluster_outputs['SECGRPS'], export_name="ECSSecGrpList")
core.CfnOutput(self, "ServicesSecGrp", value=self.services_3000_sec_group.security_group_id, export_name="ServicesSecGrp")
```

When the stack is done building, it will print out all of the outputs for the underlying CloudFormation stack. These outputs are what we use to reference the base platform when deploying the microservices. Below is an example of what the outputs look like:

```bash
   ecsworkshop-base

Outputs:
ecsworkshop-base.NSName = service
ecsworkshop-base.NSId = ns-jxsmy6sggusms4vr
ecsworkshop-base.ECSClusterName = ecsworkshop-base-ECSCluster7D463CD4-123JC9IHENY94
ecsworkshop-base.FE2BESecGrp = sg-0681f217a4d567ece
ecsworkshop-base.NSArn = arn:aws:servicediscovery:us-west-2:123456789:namespace/ns-jxsmy6sggusms4vr
ecsworkshop-base.ServicesSecGrp = sg-0681f217a4d567ece
ecsworkshop-base.ECSClusterSecGrp = []

Stack ARN:
arn:aws:cloudformation:us-west-2:123456789:stack/ecsworkshop-base/afe381b0-58e1-11ea-8997-02e1301110e6
```

That's it, we have deployed the base platform. Now let's move on to deploying the microservices.