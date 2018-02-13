+++
title = "Acceptance and Production"
chapter = false
weight = 7
+++

Let's bring up the Acceptance and Production environments

```
cd ~/environment/ecsdemo-platform
```

```
mu env up acceptance && mu env up production
```
  - This will probably take 15 minutes

```
mu pipeline up
```
  - paste your personal GitHub token
  - This will probably take 10 minutes
