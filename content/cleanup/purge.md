+++
title = "Purge"
chapter = false
weight = 10
+++

Let's clean up the CodeBuild, CodePipeline, ECS, VPC and IAM resources that mu created.  First, you can see what will be deleted by running purge in dryrun mode:

```
mu -d purge --confirm
```

To cleanup all the stacks, run:

```
mu purge --confirm
```

{{% notice tip %}}
This will take 10 minutes to cleanup all the stacks.
{{% /notice %}}