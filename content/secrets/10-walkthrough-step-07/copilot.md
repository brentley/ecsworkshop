---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Again - copilot is on autopilot.   The `init` command will deploy the application to a test environment when you choose the option to deploy a local environment.   If you choose not to deploy to a local environment, the cli will output the following commands

```bash
- Run `copilot env init --name test --profile default --app ecsworkshop` to create your staging environment.
- Update your manifest copilot/ecs-secrets-service/manifest.yml to change the defaults.
- Run `copilot svc deploy --name ecs-secrets-service --env test` to deploy your service to a test environment.
```

The last step for this tutorial is to copy the LoadBalancer URL from the last output and run:

```bash
curl ECSST-Farga-xxxxxxxxxx.yyyyy.elb.amazonawss.com/migrate | jq
```

This creates the database schema for the sample application.  To view the app, open a browser and go to the Loadbalancer URL `ECSST-Farga-xxxxxxxxxx.yyyyy.elb.amazonaws.com`:
![Secrets Todo](/images/secrets-todo.png)

This is a fully functional todo app.  Try creating, editing, and deleting todos.  Using the information output from deploy along with the secrets stored in Secrets Manager, connect to the Postgres Database using a database client or the `psql` command line tool to browse the database. 