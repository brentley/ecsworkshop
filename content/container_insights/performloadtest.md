---
title: "Perform Load testing"
chapter: false
weight: 35
---

#### Run Siege to Load Test the application 

From your terminal window in the Siege directory, run the following command. 

```
siege -c 200 -i {YOURLOADBALANCER URL}
```

This command tells Siege to run 200 concurrent connections to the ECS application at varying URLS. You should see an output like the below. At first it will show connections to the root of your site, and then you should start to see it jump around to various URLS of your site.

Let this test run for 15-20 seconds then you can kill it with ctrl+c in your terminal window. You can let it run for longer but within about 30 seconds you’ll max the open connections of the cluster and it will terminate itself.

![Cluster Dashboard](/images/ContainerInsights15.png)

#### Now let’s go view our newly collected metrics!

