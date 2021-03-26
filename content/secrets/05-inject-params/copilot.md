---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Now we will add a secure parameter via the AWS SSM Parameter STore.  This secure parameter is a path to an image that the application will display.  

```bash
APP=$(copilot svc show --json | jq -r .application)
CENV=$(copilot svc show --json | jq -r .configurations[].environment)
aws ssm put-parameter --name DEMO_PARAMETER --value "static/parameter-diagram.png" --type SecureString --tags Key=copilot-environment,Value=$CENV Key=copilot-application,Value=$APP
```

The parameter is created with the correct copilot application name and environment value as tags so copilot knows how to retrieve it.  

```json
{
    "Tier": "Standard", 
    "Version": 1
}
```

Next, inside of our `manifest.yml` file we add a section called called `secrets`.   Any secure parameter from SSM can be accessed via this area in the manifest.   The key is the name of the environment variable, the value is the name of the SSM parameter.  Paste the code below to append to the `manifest.yml` file.

```bash
cat << EOF >> copilot/todo-app/manifest.yml
secrets:                      # Pass secrets from AWS Systems Manager (SSM) Parameter Store.
  DEMO_PARAMETER: DEMO_PARAMETER  # The key is the name of the environment variable, the value is the name of the SSM parameter.
EOF
```

The value of the secure string inside SSM Parameter store will be available to your app via the `DEMO_PARAMETER` environment variable.

Now that the secure parameter secret value has been added, the ECS service running task needs to pick up the newly defined parameter.  

First we must commit the change to the local git repository - copilot only picks up committed changes in a git-enabled project.

```bash
git commit -am "Added Secrets to manifest"
```

Next, we trigger a copilot deployment for the ECS Task Definition to receive the new parameter. We pass the arbitrary tag of "update-credentials" to force the new deployment.

```bash
copilot svc deploy --tag update-credentials
```

Head back to the ECS Console to check on progress - this usually takes 1-2 minutes.  Once the task is running, go back to the todo app and refresh, you should see a fully functional app once again with a diagram displayed.

![working-app](/images/secrets-parameter-store-working.png)