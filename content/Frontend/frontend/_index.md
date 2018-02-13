+++
title = "Deploy the Frontend Pipeline"
chapter = false
weight = 8
+++

Deploy the CodePipeline for the Rails Frontend App

```
cd ~/environment/ecsdemo-frontend
```

```
mu pipeline up
```
  - paste your personal GitHub token
  - This will take 5 minutes

When the pipeline is built and running, monitor it's progress with:
```
mu pipeline logs acceptance -f
```
