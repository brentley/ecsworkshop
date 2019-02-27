---
title: "Acceptance and Production"
disableToc: true
hidden: true
---

- Clone the demo repository:

```
cd ~/environment
git clone https://github.com/brentley/fargate-demo.git
```

- Ensure service linked roles exist for Load Balancers and ECS:

```
aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"

aws iam get-role --role-name "AWSServiceRoleForECS" || aws iam create-service-linked-role --aws-service-name "ecs.amazonaws.com"
```


- Build a VPC, ECS Cluster, and ALB:
 
```
cd ~/environment/fargate-demo

aws cloudformation deploy --stack-name fargate-demo --template-file cluster-fargate-private-vpc.yml --capabilities CAPABILITY_IAM

aws cloudformation deploy --stack-name fargate-demo-alb --template-file alb-external.yml
```

