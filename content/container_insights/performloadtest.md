---
title: "Perform Load testing"
chapter: false
weight: 35
---

#### Run Siege to Load Test the application 

Let's grab the load balancer url to begin the load testing.

```
alb_url=$(aws cloudformation describe-stacks --stack-name container-demo-alb --query 'Stacks[0].Outputs[?OutputKey==`ExternalUrl`].OutputValue' --output text 2> /dev/null || aws cloudformation describe-stacks --stack-name ecsworkshop-frontend | jq -r '.Stacks[].Outputs[] | select(.OutputKey | contains("FrontendFargateLBServiceServiceURL")) | .OutputValue')
```

*Note*: if you see an error

From your terminal window in the Siege directory, run the following command. 

```
siege -c 200 -i $alb_url
```

This command tells Siege to run 200 concurrent connections to the ECS application at varying URLS. You should see an output like the below. At first it will show connections to the root of your site, and then you should start to see it jump around to various URLS of your site.

Let this test run for 15-20 seconds then you can kill it with ctrl+c in your terminal window. You can let it run for longer but within about 30 seconds you’ll max the open connections of the cluster and it will terminate itself.

![Cluster Dashboard](/images/ContainerInsights15.png)

#### Now let’s go view our newly collected metrics!

