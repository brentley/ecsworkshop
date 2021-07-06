---
title: "Visualize metrics"
draft: false
weight: 11
---

#### Configure AMP data source

Select `AWS services` from the AWS logo on the left navigation bar, which will take you to the screen as shown below showing all the AWS data sources available for you to choose from.

![AWS Datasources](/images/amg8.png)

Select Amazon Managed Service for Prometheus from the list, select the AWS Region where you created the AMP workspace. This will automatically populate the AMP workspaces available in that Region as shown below.


![AMP data source config](/images/amg9.png)

Simply select the AMP workspace from the list and click `Add data sources`.

#### Visualize Metrics

In this section we will be importing sample Grafana dashboard that allows us to visualize metrics from a ECS environment.

Download provided sample dashboard to your computer

```bash
curl https://raw.githubusercontent.com/petrokashlikov/ecsdemo-amp/main/grafana/AMP_ECS_Task_Monitoring.json -o AMP_ECS_Task_Monitoring.json
```

Go to the `plus` sign on the left navigation bar and select `Import`.
![Import link](/images/amg10.png)

In the Import screen, click Upload JSON file and select dashboard file that you just downloaded and make sure you select your AMP data source in the drop down at the bottom and click on `Import`


Once completed, you will be able to see the Grafana dashboard showing metrics from the ECS cluster through AMP data source as shown below.

![Sample Dashboard](/images/amg11.png)

You can also create your own custom dashboard using PromQL by creating a custom dashboard and adding a panel connecting AMP as the data source.