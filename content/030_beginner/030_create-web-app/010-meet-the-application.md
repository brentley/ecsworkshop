---
title: "Meet the application"
chapter: false
weight: 1
---

The first application we are going to deploy is a basic website with static HTML content. This type of
website could also be hosted in an S3 bucket, but in some cases you may want to have the extra control
of running your own HTTP server.

We are going to build an NGINX web server inside a container, and add our HTML page to the container
for NGINX to host. Finally we will host the container on AWS Fargate, behind a load balancer.

![diagram.png](/images/basic-web-app-diagram.png)