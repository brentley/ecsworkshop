+++
title = "Dry Run"
chapter = false
draft = true
weight = 2
+++

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
