---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Now we will change the secure parameter defined earlier in the tutorial.   This secure parameter is a path to an image that the application will display.  

```bash
APP=$(copilot svc show --json | jq -r .application)
CENV=$(copilot svc show --json | jq -r .configurations[].environment)
aws ssm put-parameter --name DEMO_PARAMETER --value "static/parameter-diagram.png" --type SecureString --overwrite
```

The parameter was created with the correct copilot application name and environment value so copilot knows how to retrieve it.  We overwrite its value by passing the `--overwrite` flag and consequently incrementing the version of the parameter.   Parameters are versioned so that you can track and rollback to previous values.  

```json
{
    "Tier": "Standard", 
    "Version": 2
}
```

Inside of our `manifest.yml` file there exists a section called `secrets`.   Any secure parameter from SSM can be accessed via this area in the manifest.   The key is the name of the environment variable, the value is the name of the SSM parameter.

The value of the secure string inside SSM Parameter store will be available to your app via the `DEMO_PARAMETER` environment variable.  This value is pre-populated in the manifest for the tutorial.  

Now that the secure parameter secret value has been changed, the ECS service running task is still using the now-stale parameter.   In order for the service to pick up the new secret, stop the running task and let the ECS Scheduler bring up a new task which will contain the updated parameter.   

Use the AWS CLI to stop the current task, and then give the service a few mins to launch a new task to get the desired count back to 1. 

```bash
CLUSTER_ARN=$(aws ecs list-clusters | jq -r .clusterArns[])
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_ARN | jq -r .taskArns[])
aws ecs stop-task --cluster $CLUSTER_ARN --task $TASK_ARN | jq
```

Head back to the ECS Console to check on progress - this usually takes 1-2 minutes.  Once the task is running, go back to the todo app and refresh, you should see a fully functional app once again with a diagram displayed. 

Once the deployment is complete, go back to the browser and you should see the app again.  

![working-app](/images/secrets-parameter-store-working.png)