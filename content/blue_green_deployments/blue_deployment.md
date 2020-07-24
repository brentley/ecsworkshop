+++
title = "Review blue deployment"
chapter = false
weight = 4
+++

#### Open the service in your browser

We can access the deployed blue version via the load balancer url. Let's open it in our browser.
Open the Load Balancer URL in your browser, here's the command to get the url:

```bash
echo "http://$load_balancer_url"
```

#### You will see blue deployment on port `80`

![blue-deployment](/images/blue-green-deployment-1.png)

* Now it's time to setup the CodeCommit repository for the Green deployment
