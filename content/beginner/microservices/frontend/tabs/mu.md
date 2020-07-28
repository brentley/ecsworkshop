---
title: "Embedded tab content"
disableToc: true
hidden: true
---


Let's do a dry run and see what CloudFormation is generated!

Copy/Paste the following commands into your Cloud9 workspace:

```
cd ~/environment/ecsdemo-frontend
mu -d pipeline up -t $GITHUB_TOKEN
ls -la /tmp/mu-dryrun
```

There should now be more stacks and parameter configs. Let's look at the parameters for building the CodePipeline:
```
less /tmp/mu-dryrun/config-${MU_NAMESPACE}-pipeline-ecsdemo-frontend.json
```

Let's look at how the pipeline for our service will be built:
```
less /tmp/mu-dryrun/template-${MU_NAMESPACE}-pipeline-ecsdemo-frontend.yml
```

{{% notice tip %}}
This will dry-run Mu and generate CloudFormation so you can examine what will be built before actually building it.
{{% /notice %}}

Now we can bring up the Frontend Pipeline:

```
cd ~/environment/ecsdemo-frontend
mu pipeline up -t $GITHUB_TOKEN
```

{{% notice info %}}
The output will include warning lines about IAM. These can be safely ignored
since we aren't building the environment with this pipeline.
{{% /notice %}}

{{% notice tip %}}
This will take 5 minutes to create the pipeline.
{{% /notice %}}

After the CodePipeline is built, [watch it run.](https://console.aws.amazon.com/codepipeline/home?region=us-east-1#/dashboard)
Once it runs, [check for deployed tasks in your ECS cluster.](https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters)

You can watch the pipeline steps in the terminal:
```
mu svc show -w -t
```

You can also follow the pipeline logs:
```
mu pipeline logs -f
```

And follow the task logs:
```
mu svc logs -f acceptance
```

{{% notice tip %}}
This will take 10 minutes for the pipeline to build and deploy the application.
{{% /notice %}}