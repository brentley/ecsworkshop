+++
title = "Blue/Green Deployments"
chapter = true
weight = 56
+++

# Blue/Green Deployments on ECS Fargate

In this chapter, we will deploy a demo application on ECS Fargate and update the application using Blue/Green deployment capability of CodeDeploy and ECS.

Blue/Green deployment is a technique for releasing an application by shifting the traffic between two identical environments running different versions of the same application. Blue/Green deployment is recommended for critical workloads since it mitigates the risks associated with deploying software, such as downtime and rollback capability.

Traditionally, with in-place upgrades, it was difficult to validate your new application version in a production deployment while also continuing to run your old version of the application. After you deploy the green environment, you have the opportunity to validate it. If you discover the green environment is not operating as expected, there is no impact on the blue environment. You can route traffic back to it, minimizing impaired operation or downtime, and limiting the blast radius of impact. 

This ability to simply roll traffic back to the still-operating blue environment is a key benefit of blue/green deployments. You can roll back to the blue environment at any time during the deployment process. 

You can read more about it in this [AWS whitepaper](https://d1.awsstatic.com/whitepapers/AWS_Blue_Green_Deployments.pdf)



Let's get started...
