---
title: "Embedded tab content"
disableToc: true
hidden: true
---

`copilot secret init` creates or updates secrets as SecureString parameters in SSM Parameter Store for your application.   A secret can have different values in each of your existing environments, and is accessible by your services or or jobs from the same application and environment.

Lets create a secret in the application.

```bash
APP=$(copilot svc show --json | jq -r .application)
CENV=$(copilot svc show --json | jq -r .configurations[].environment)
copilot secret init --app $APP --name DEMO_PARAMETER --values $CENV=static/parameter-diagram.png
```

The parameter is created with the correct copilot application name and environment value as tags so copilot knows how to retrieve it.

```
Environment test is already on the latest version v1.4.0, skip upgrade.
...Put secret DEMO_PARAMETER to environment test
✔ Successfully put secret DEMO_PARAMETER in environment test as /copilot/ecsworkshop2322/test/secrets/DEMO_PARAMETER.
You can refer to these secrets from your manifest file by editing the `secrets` section.
test
  secrets:
    DEMO_PARAMETER: /copilot/ecsworkshop2322/test/secrets/DEMO_PARAMETER
```

Next, inside of our `manifest.yml` file we add a section called called `secrets`.   Any secure parameter from SSM can be accessed via this area in the manifest.   The key is the name of the environment variable, the value is the name of the SSM parameter.  Paste the code below to append to the `manifest.yml` file.

```bash
cat << EOF >> copilot/todo-app/manifest.yml
secrets:
    DEMO_PARAMETER: /copilot/ecsworkshop2322/test/secrets/DEMO_PARAMETER
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