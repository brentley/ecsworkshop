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

- Build a VPC, ECS Cluster, and ALB:
 
```
cd ~/environment/fargate-demo

aws cloudformation deploy --stack-name fargate-demo --template-file cluster-fargate-private-vpc.yml --capabilities CAPABILITY_IAM

aws cloudformation deploy --stack-name fargate-demo-alb --template-file alb-external.yml
```

