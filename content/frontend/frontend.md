+++
title = "Deploy the Frontend Pipeline"
chapter = false
weight = 2
+++

Let’s bring up the Frontend Rails application!

Copy/Paste the following commands into your Cloud9 workspace:

```
cd ~/environment/ecsdemo-frontend
mu pipeline up
```
Paste your personal GitHub token

{{% notice tip %}}
This will take 10 minutes
{{% /notice %}}

After the CodePipeline is built, [watch it run](https://console.aws.amazon.com/codepipeline/home?region=us-east-1#/view/mu-ecsdemo-frontend)

You can also follow the logs:
```
mu pipeline logs -f
```
