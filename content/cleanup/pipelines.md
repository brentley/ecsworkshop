+++
title = "Pipelines"
chapter = false
weight = 1
+++

Let's clean up the pipelines in reverse order:

```
cd ~/environment/ecsdemo-crystal
mu pipeline term

cd ~/environment/ecsdemo-nodejs
mu pipeline term

cd ~/environment/ecsdemo-frontend
mu pipeline term

cd ~/environment/ecsdemo-platform
mu pipeline term
```

{{% notice note %}}
This _only_ terminates the CI/CD process for code changes. The services are still running.
{{% /notice %}}
