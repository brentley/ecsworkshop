---
title: "Acceptance and Production"
disableToc: true
hidden: true
---

- Build a VPC, ECS Cluster, CloudMap Service Discovery Namespace, as well as dependent security group to allow frontend service to talk to backend services:
 
```bash
cd ~/environment/container-demo

# View proposed changes to the environment
cdk diff

# Deploy the changes to the environment
cdk deploy
```

Let's take a look at what's being built. You may notice that everything defined in the stack is 100% written as python code. We also benefit from the opinionated nature of cdk by letting it build out components based on well architected practices. This also means that we don't have to think about all of the underlying components to create and connect resources (ie, subnets, nat gateways, etc). Once we deploy the cdk code, the cdk will generate the underlying Cloudformation templates and deploy it to the environment via Cloudformation.

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
```
