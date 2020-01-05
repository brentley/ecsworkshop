---
title: "Setup Alarms on CloudWatch Metrics"
chapter: false
weight: 37
---

#### CloudWatch Alarms

The metrics captured through Container Insights can be used to setup Alarms to get notified of any anomalies in the environment behavior.

In CloudWatch Container Insights we’re going to drill down to create an alarm using CloudWatch for CPU Utilization for our application. Select **ECS Services** and click on the three vertical dots in the upper right of the CPU Utilization box. And select **View in Metrics**.

![Cluster Dashboard](/images/ContainerInsights18.png)

This will take you to a screen such as the one below. You can see that the **ecsdemo-frontend** service had its CPU Utilization spike quite a bit. Let's go ahead and setup an Alarm on this metric by clicking the 🔔icon corresponding to **ecsdemo-frontend** line item. 

![Cluster Dashboard](/images/ContainerInsights19.png)

In the **Specify metric conditions** screen, leave everything as default and enter **50** in the **Define the threshold value** screen. By doing this, we are setting the CPU Utilization threshold for the alarm to be 50%. Select **Next**

![Cluster Dashboard](/images/ContainerInsights20.png)

In the **Configure actions** screen, select **Create new topic** option and enter an email id to which you want the alarm notifications to be sent. Select **Next**

![Cluster Dashboard](/images/ContainerInsights21.png)

In the **Add a description** screen, enter a name for the alarm and select **Next**

![Cluster Dashboard](/images/ContainerInsights22.png)

In the review screen, select **Create alarm** to create the alarm. Once complete, you should be able to see a screen such as the one below. 

![Cluster Dashboard](/images/ContainerInsights23.png)

Now, go to your email Inbox that you entered and look for a confirmation email and confirm that you want to receive alarm notifications from CloudWatch.

![Cluster Dashboard](/images/ContainerInsights24.png)

Once you click on **Confirm subscription**, you should see a confirmation screen like the one below.

![Cluster Dashboard](/images/ContainerInsights25.png)
