---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Now let's add a secure parameter that the application will read to display an image.  First, create the secure parameter:

```bash
APP=$(copilot svc show --json | jq -r .application)
CENV=$(copilot svc show --json | jq -r .configurations[].environment)
aws ssm put-parameter --name DEMO_PARAMETER --value "static/parameter-diagram.png" --type SecureString --tags Key=copilot-environment,Value=$CENV Key=copilot-application,Value=$APP
```
Note that the secure parameter is tagged with the copilot application name. The parameter is tagged with the current copilot application name and environment value. 

Modify the `copilot\todo-app\manifest.yml` adding `secrets` section.  Copy and paste the below into the Cloud9 terminal which will append the secrets section. 

```yml
cat << EOF >> copilot/todo-app/manifest.yml
secrets:                      # Pass secrets from AWS Systems Manager (SSM) Parameter Store.
  DEMO_PARAMETER: DEMO_PARAMETER  # The key is the name of the environment variable, the value is the name of the SSM parameter.
EOF
```

The value of the secure string inside SSM Parameter store will be available to your app via the `DEMO_PARAMETER` environment variable.  

In order to update the task, first commit the change made to the manifest file:

```bash
git commit -am "update manifest.yml"
```

When copilot does a new deployment, it uses the latest commit to build the deployment, so our manifest change needs to be checked into the local git repository.

Then, redeploy the copilot service:

```bash
copilot svc deploy --tag update-manifest

```

Once the deployment is complete, go back to the browser and you should see the app again.  

![working-app](/images/secrets-parameter-store-working.png)