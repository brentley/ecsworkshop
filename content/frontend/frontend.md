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

{{% notice warning %}}
If using Cloud9, paste using ctrl-v, not the mouse right-click.
Pasting with mouse-clicks is a known issue with Cloud9.
{{% /notice %}}

{{% notice tip %}}
This will take 10 minutes
{{% /notice %}}

After the CodePipeline is built, [watch it run](https://console.aws.amazon.com/codepipeline/home?region=us-east-1#/view/mu-ecsdemo-frontend)

You can also follow the logs:
```
mu pipeline logs -f
```
