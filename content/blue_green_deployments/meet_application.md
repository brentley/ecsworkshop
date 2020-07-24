+++
title = "Meet the application"
chapter = false
weight = 1
+++

We will be deploying a demo application to ECS Fargate. 

* This application will be a static web page running on NGINX as a Fargate service
* CodePipeline will be used for executing Blue/Green deployment using CodeCommit, CodeBuild and CodeDeploy
* The container images will be stored in the Elastic Container Registry

Below is a diagram of the environment we will be building:

![blue-green-meet-application](/images/blue-green-meet-application.png)
