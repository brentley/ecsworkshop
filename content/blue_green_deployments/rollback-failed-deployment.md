+++
title = "Rollback failed deployment"
chapter = false
weight = 7
+++

Here we will trigger an automated rollback but simulating a 500 error.

#### Edit the `nginx.conf` to return a 500 error instead of default `index.html`

![Edit-Nginx-conf](/images/blue-green-edit-nginx-conf.gif)

{{%expand "Expand to see the complete nginx.conf" %}}
```
# Run as a less privileged user for security reasons.
user nginx;

# Number of worker_threads to run;
# "auto" sets it to the #CPU_cores available in the system, and
# offers the best performance.
worker_processes    auto;

events { worker_connections 1024; }

http {
    server {
        # Hide nginx version information.
        server_tokens off;

        listen  80;
        root    /usr/share/nginx/html;
        include /etc/nginx/mime.types;

        location / {
            return 500;
        }

        gzip            on;
        gzip_vary       on;
        gzip_http_version  1.0;
        gzip_comp_level 5;
        gzip_types
                        application/atom+xml
                        application/javascript
                        application/json
                        application/rss+xml
                        application/vnd.ms-fontobject
                        application/x-font-ttf
                        application/x-web-app-manifest+json
                        application/xhtml+xml
                        application/xml
                        font/opentype
                        image/svg+xml
                        image/x-icon
                        text/css
                        text/plain
                        text/x-component;
        gzip_proxied    no-cache no-store private expired auth;
        gzip_min_length 256;
        gunzip          on;
    }
}
```
{{% /expand %}}

#### Push the code to the CodeCommit repository
```bash
cd ~/environment/nginx-example
git add .
git commit -m "Returning 500 error"
git push
``` 

#### The code push will trigger the CodePipeline

![Rollback-Deployment](/images/blue-green-rollback-deployment.gif)

* The CodeDeploy initiates the deployment as before
* Once the **Step 3** traffic shifting is started, we open the service in your browser on the Load Balancer port `80`

Here is the command to get the url:

```bash
echo "http://$load_balancer_url"
```
* You will notice the page returning **500 Internal Server Error**
* We have configured CloudWatch alarms which will look for 5XX errors from the ELB target groups

{{%expand "Expand to see the code" %}}
```typescript
// CloudWatch Alarms for 5XX errors
const blue5xxMetric = new cloudWatch.Metric({
    namespace: 'AWS/ApplicationELB',
    metricName: 'HTTPCode_Target_5XX_Count',
    dimensions: {
        TargetGroup: blueGroup.targetGroupFullName,
        LoadBalancer: alb.loadBalancerFullName
    },
    statistic: cloudWatch.Statistic.SUM,
    period: Duration.minutes(1)
});
const blueGroupAlarm = new cloudWatch.Alarm(this, "blue5xxErrors", {
    alarmName: "Blue_5xx_Alarm",
    alarmDescription: "CloudWatch Alarm for the 5xx errors of Blue target group",
    metric: blue5xxMetric,
    threshold: 1,
    evaluationPeriods: 1
});

const green5xxMetric = new cloudWatch.Metric({
    namespace: 'AWS/ApplicationELB',
    metricName: 'HTTPCode_Target_5XX_Count',
    dimensions: {
        TargetGroup: greenGroup.targetGroupFullName,
        LoadBalancer: alb.loadBalancerFullName
    },
    statistic: cloudWatch.Statistic.SUM,
    period: Duration.minutes(1)
});
const greenGroupAlarm = new cloudWatch.Alarm(this, "green5xxErrors", {
    alarmName: "Green_5xx_Alarm",
    alarmDescription: "CloudWatch Alarm for the 5xx errors of Green target group",
    metric: green5xxMetric,
    threshold: 1,
    evaluationPeriods: 1
});
```
{{% /expand %}}

* The CodeDeploy is configured to initiate automatic rollback if the CloudWatch Alarms are **In Alarm** state
* The CodeDeploy will stop the deployment
* CodeDeploy will now re-route the production traffic to original task set
* Finally, CodeDeploy will terminate the replacement task set
* Refresh the service on the browser and the original **Green background** deployment will be visible

That's it. You have successfully completed a Blue/Green Deployment and done automatic rollback of a failed deployment.
Let's review the configurations files now.


