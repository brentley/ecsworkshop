+++
title = "CodePipeline Primer"
chapter = false
weight = 2
+++

[AWS CodePipeline](https://aws.amazon.com/codepipeline/) is a fully managed [continuous delivery](https://aws.amazon.com/devops/continuous-delivery/) service that helps you automate your release pipelines for fast and reliable application and infrastructure updates. CodePipeline automates the build, test, and deploy phases of your release process every time there is a code change, based on the release model you define.

![blue-green-code-pipeline](/images/blue-green-code-pipeline.png)

With a blue/green deployment, you provision a new set of containers on which [CodeDeploy](https://aws.amazon.com/codedeploy) installs the latest version of your application. CodeDeploy then reroutes load balancer traffic from an existing set of containers running the previous version of your application to the new set of containers running the latest version. After traffic is rerouted to the new containers, the existing containers can be terminated. Blue/green deployments allow you to test the new application version before sending production traffic to it. 

![blue-green-primer](/images/blue-green-primer.png)


If there is an issue with the newly deployed application version, you can roll back to the previous version faster than with in-place deployments. Additionally, the containers provisioned for the blue/green deployment will reflect the most up-to-date server configurations since they are new.

