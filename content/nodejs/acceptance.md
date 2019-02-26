+++
title = "Verify the Acceptance Deploy"
chapter = false
draft = true
weight = 3
+++

Once our Node.js Backend API is deployed to the Acceptance
environment, we can verify that it's running and available.

To find the URL of the acceptance environment, run this command:
```
mu env show acceptance
```
Follow the **Base URL** link and confirm that your application
now uses the Node.js backend api.

Check the running tasks in the [Acceptance ECS Cluster](https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/mu-environment-acceptance/tasks)
