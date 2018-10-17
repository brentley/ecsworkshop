+++
title = "Pipelines"
chapter = false
weight = 10
draft = true
+++

Let's clean up the pipelines in reverse order:

```
cd ~/environment/ecsdemo-crystal
mu pipeline term

cd ~/environment/ecsdemo-nodejs
mu pipeline term

cd ~/environment/ecsdemo-frontend
mu pipeline term
```

{{% notice note %}}
This _only_ terminates the CI/CD pipelines for building from code changes. The services are still running.
{{% /notice %}}
