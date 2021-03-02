---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Next run `cdk synth` to create the cloudformation templates which output to a local directory `cdk.out`.   Successful output will contain (ignore any warnings generated):

```bash
Successfully synthesized to /home/ec2-user/environment/secret-ecs-cdk-example/cdk.out
Supply a stack id (VPCStack, RDSStack, ECSStack) to display its template.
```

Finally - deploy all of the stacks using the CDK:

```bash
cdk deploy --all
```

The process takes approximately 10 minutes.  A prompt will appear to authorize changes.  Pass the parameter `--require-approval never` to the above command for unattended installation.   A successful deployment will look like:

![CDK Output 1](/images/cdk-output-1.png)
![CDK Output 2](/images/cdk-output-2.png)

The last step for this tutorial is to copy the LoadBalancer URL from the above output and run

```bash
curl ECSST-Farga-xxxxxxxxxx.yyyyy.elb.amazonawss.com/migrate | jq
```

The `migrate` method creates the database schema and a single row of data for the sample application.  To view the app, open a browser and go to the Loadbalancer URL `ECSST-Farga-xxxxxxxxxx.yyyyy.elb.amazonaws.com`:
![Secrets Todo](/images/secrets-todo.png)

This is a fully functional todo app.  Try creating, editing, and deleting todos.  Using the information output from deploy along with the secrets stored in Secrets Manager, connect to the Postgres Database using a database client or the `psql` command line tool to browse the database.   You may also browse the database using the Query Editor tool inside the RDS section of the AWS Console.