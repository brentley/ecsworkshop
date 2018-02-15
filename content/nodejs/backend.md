+++
title = "Deploy the Backend Pipeline"
chapter = false
weight = 2
+++

Let’s bring up the Node.js Backend API!

Copy/Paste the following commands into your Cloud9 workspace:

```
cd ~/environment/ecsdemo-nodejs
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
