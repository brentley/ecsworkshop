+++
title = "Capacity Providers"
chapter = true
weight = 54
+++

# Amazon ECS Cluster Capacity Providers

In this chapter, we will gain an understanding of how Capacity Providers can help us in managing autoscaling for EC2 backed tasks, as well as ways to implement cost savings when running Fargate tasks.
We will implement two capacity provider strategies in our cluster: 

1) For an EC2 backed ECS service, we will implement Cluster Auto Scaling, and add load to that service. This will trigger service autoscaling, which will ultimately require the backend EC2 infrastucture to scale to meet the demand. 


2) For a Fargate backed ECS service, we will implement a strategy to deploy that service to be split 50/50 between Fargate and Fargate Spot.

Let's get started!

