---
title: "Trigger CloudWatch alarm"
chapter: false
weight: 38
---

#### Create load to trigger CloudWatch alarm

We are going to use Siege once again to create load on the environment so the alarm can be triggered.

Execute the following command on your Cloud9 Workspace and watch for the CPU Utilization to go up.

```
siege -c 200 -i {YOURLOADBALANCER URL}
```
In about 5 minutes or so you will see the CPU Utilization crossing the 50% mark as shown below. 

![Cluster Dashboard](/images/ContainerInsights26.png)

This will trigger the alarm we configured earlier. Notice the state of the alarm is **In alarm** as shown below.

![Cluster Dashboard](/images/ContainerInsights27.png)

You will also receive an email notification such as the one below.
![Cluster Dashboard](/images/ContainerInsights28.png)


