+++
title = "Promote to Production"
chapter = false
draft = true
weight = 4
+++

When we're happy that the acceptance environment is running our api,
we can release this code to our Production environment.

Go to [CodePipeline](https://console.aws.amazon.com/codepipeline/home?region=us-east-1#/dashboard)
and find the pipeline for your service
[mu-ecsdemo-nodejs](https://console.aws.amazon.com/codepipeline/home?region=us-east-1#/view/mu-ecsdemo-nodejs)

Scroll down to **Production** and you should see a *Manual approval step*.
Select **Review**, fill in a _reason_ and select **Approve**

The same container that is deployed to **Acceptance** will now be deployed to **Production**

Check the running tasks in the [Production ECS Cluster](https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/mu-environment-production/tasks)

To see the **Production** URL, run this command:
```
mu env show production
```
When you see tasks running in the cluster, follow the **Base URL** link and confirm that your application
now uses the backend API.
