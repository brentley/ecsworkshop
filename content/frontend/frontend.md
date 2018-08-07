+++
title = "Deploy the Frontend Pipeline"
chapter = false
weight = 3
+++

Let’s bring up the Frontend Rails application!

Copy/Paste the following commands into your Cloud9 workspace:

```
cd ~/environment/ecsdemo-frontend
mu pipeline up -t $GITHUB_TOKEN
```

{{% notice info %}}
The output will include warning lines about IAM. These can be safely ignored
since we aren't building the environment with this pipeline.
{{% /notice %}}

{{% notice tip %}}
This will take 10 minutes.
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
