+++
title = "Test Functionality"
chapter = false
weight = 6
+++

#### Open the service in your browser

Now that the service is created, we can access it via the load balancer url. Let's grab that and open it in our browser.

Open the Load Balancer URL in your browser, here's the command to get the url:

**NOTE**: It may take a couple of minutes before you can access the url

```bash
echo "http://$load_balancer_url"
```

#### Add a directory to the UI

The web interface should look something like this:

![cc-ui](/images/cc-ui.png)

At the bottom of the interface, you should see `F7`, Click that, and name the directory `EFS_DEMO`

![cc-bottom](/images/cc-bottom.png)

Now you should see a directory named `EFS_DEMO`. This file is stored on the EFS volume that is mounted to the container. To showcase this, let's go ahead and kill the task, and when the scheduler brings up a new one, we should see the same directory.


#### Stop the task and go back to the UI

To stop the task: 

```bash
task_arn=$(aws ecs list-tasks --cluster $cluster_name --service-name cloudcmd-rw | jq -r .taskArns[])
aws ecs stop-task --task $task_arn --cluster $cluster_name
```

When you go back to the Load Balancer URL in the browser, you should see a 503 error. 

#### Wait for the new task, and confirm the directory we created is showing

In a couple of minutes, head back to the URL and you should see the UI again. Also, you should see your directory `EFS_DEMO` listed.

That's it! You've successfully created a stateful service in Fargate and watched as a task serving the data went away, and was replaced with the same stateful backend storage layer.
