+++
title = "Review the green deployment"
chapter = false
weight = 6
+++

#### Click on the Deploy phase of the pipeline

* This will navigate you to the deployment status for the ECS service

![CodeDeploy-taskset-replacement](/images/blue-green-code-deploy-taskset-replacement.gif)

* **Step 1:** will deploy the replacement task set based on the `taskdef.json` and new image created by the build phase
* **Step 2:** will setup the new tasks and enable the test listener on the port `8080`
* Once **Step 2:** is completed, open the service in your browser on the Load Balancer Test listener port `8080`

Here is the command to get the url:

```bash
echo "http://$load_balancer_url:8080"
```

You will see the demo application with a changed background colour of green.

![green-deployment](/images/blue-green-deployment-2.png)

* **Step 3:** initiates the traffic shifting from Blue to Green deployment
    * We have a seamless traffic shifting from blue to green using the deployment configuration - `CodeDeployDefault.ECSLinear10PercentEvery1Minutes`. We shift 10 percent of traffic every minute until all traffic is shifted
    * Once completed, port `80` will display the **Green Deployment**
 
Here is the command to get the url:

```bash
echo "http://$load_balancer_url"
```

* **Step 4** is where the old task set is retained for 10 minutes. This time period is configurable via the CDK stack
* **Step 5** will terminate the original task set

We have completed a successful Blue/Green deployment. Let's now do rollback of a failed deployment
