---
title: "Embedded tab content"
disableToc: true
hidden: true
---


Create the secure parameter:

```bash
aws ssm put-parameter --name GH_WEBHOOK_SECRET --value secretvalue1234 --type SecureString --tags Key=copilot-environment,Value=test Key=copilot-application,Value=ecsworkshop
```
Note that the secure parameter is tagged with the copilot application name.  Important:  The `application` tag must match the application name used in the copilot app creation process, here we used `ecsworkshop`

Modify the `copilot\todo-app\manifest.yml` and add a value the `secrets` section:

```yml
secrets:                      # Pass secrets from AWS Systems Manager (SSM) Parameter Store.
  GITHUB_TOKEN: GH_WEBHOOK_SECRET  # The key is the name of the environment variable, the value is the name of the SSM parameter.x 
```

The value of the secure string inside SSM Parameter store will be available to your app via the `GH_WEBHOOK_SECRET` variable.  Secret names are customizable - choose any key and value needed.