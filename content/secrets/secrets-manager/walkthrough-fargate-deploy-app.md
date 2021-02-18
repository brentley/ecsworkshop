---
title: "Deploy the Application"
chapter: false
weight: 33
---

Next we run `cdk synth` to create the cloudformation templates which output to a local directory `cdk.out`.   If successful, you will see this:

```
Successfully synthesized to /home/ec2-user/environment/secret-ecs-cdk-example/cdk.out
Supply a stack id (VPCStack, RDSStack, ECSStack) to display its template.
```

Finally - we deploy all of the stacks using the CDK:

```
cdk deploy --require-approval never --all
```

The process takes approximately 10 minutes.   If all is succesesfuly, you will see:

![CDK Output 1](/images/cdk-output-1.png)
![CDK Output 2](/images/cdk-output-2.png)

The last step for this tutorial is to copy the LoadBalancerDNS name from the above output and run
```
curl ECSST-Farga-xxxxxxxxxx.yyyyy.elb.amazonawss.com/migrate
```

This creates the database schema for the sample application.  To view the app, open a browser and go to the Loadbalancer URL `ECSST-Farga-xxxxxxxxxx.yyyyy.elb.amazonawss.com` - you will see:
![Secrets Todo](/images/secrets-todo.png)

This is a fully functional todo app, try creating, editing, and deleting todos.  If you want to look at the database, using the information output from deploy along with the secrets stored in Secrets Manager, connect to the Postgres Database using your preferred database client or the `psql` command line tool. 