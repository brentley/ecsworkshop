---
title: "CloudWatch Logs Insights"
chapter: false
weight: 40
---

#### What is Logs Insights?
[CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html) is a fully integrated, interactive, and pay-as-you-go log analytics service for CloudWatch. CloudWatch Logs Insights enables you to explore, analyze, and visualize your logs instantly, allowing you to troubleshoot operational problems with ease.

#### Querying Logs from ECS

Navigate to [CloudWatch Logs Insights](https://console.aws.amazon.com/cloudwatch/home#logs-insights:) and select **/aws/ecs/containerinsights/_cluster-name_/performance** Log Group as shown below

![Logs Insights](/images/ContainerInsights8.png)

Copy and paste the following query into the textbox and click Run query
```
stats count_distinct(TaskId) as Number_of_Tasks by ServiceName
```
This query returns a table showing the number of Tasks running by Service as shown below

![Number of Tasks by Service Name](/images/ContainerInsights9.png)

-----------

The following query returns a table showing the average Memory and CPU Utilized by Tasks every 5 minutes using the **filter** command
```
stats avg(MemoryUtilized) as Avg_Memory, avg(CpuUtilized) as Avg_CPU by bin(5m)
| filter Type="Task"
```
![Number of Tasks by Service Name](/images/ContainerInsights10.png)

------------

You can also visualize the output on a graph by simply clicking on the **Visualization** tab. The following screenshot shows a bar chart of the same report

![Number of Tasks by Service Name](/images/ContainerInsights11.png)
