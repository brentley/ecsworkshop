+++
title = "Build the Environments"
chapter = false
weight = 6
+++

In the Cloud9 workspace, run the following commands:

- Ensure service linked roles exist for Load Balancers and ECS:

```
aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"

aws iam get-role --role-name "AWSServiceRoleForECS" || aws iam create-service-linked-role --aws-service-name "ecs.amazonaws.com"
```


{{< tabs name="Build the environments" >}}
{{< tab name="copilot-cli" include="tabs/copilot.md" />}}
{{< tab name="cdk" include="tabs/cdk.md" />}}
{{< tab name="ecs-cli fargate mode" include="tabs/ecscli.md" />}}
{{< tab name="ecs-cli ec2 mode" include="tabs/ecscli-ec2-mode.md" />}}
{{< /tabs >}}

