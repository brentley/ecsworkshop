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
  - paste your personal GitHub token
{{% notice tip %}}
This will take 5 minutes
{{% /notice %}}

After the pipeline is built, monitor it's progress:
```
mu pipeline logs acceptance -f
```
