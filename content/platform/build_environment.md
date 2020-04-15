+++
title = "Build the Environments"
chapter = false
weight = 6
+++

In the Cloud9 workspace, run the following commands:

- Clone the demo repository:

```
cd ~/environment
git clone https://github.com/brentley/container-demo
```

- Ensure service linked roles exist for Load Balancers and ECS:

```
aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"

aws iam get-role --role-name "AWSServiceRoleForECS" || aws iam create-service-linked-role --aws-service-name "ecs.amazonaws.com"
```


{{< tabs name="Build the Acceptance and Production Environments" >}}
{{< tab name="cdk: Fargate mode" include="tabs/cdk.md" />}}
{{< tab name="cdk: EC2 mode" include="tabs/cdkec2.md" />}}
{{< tab name="ecs-cli fargate mode" include="tabs/ecscli.md" />}}
{{< tab name="ecs-cli ec2 mode" include="tabs/ecscli-ec2-mode.md" />}}
{{< /tabs >}}

