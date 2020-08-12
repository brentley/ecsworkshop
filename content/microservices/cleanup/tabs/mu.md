---
title: "Embedded tab content"
disableToc: true
hidden: true
---

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

Go to https://github.com/settings/tokens and delete the token labeled **workshop**

Go to https://github.com/settings/ssh/ and delete the key labeled **workshop**

{{% notice note %}}
This removes the token and ssh key used in the workspace. This is good security practice.
The public repositories are free and can stay in case you'd like to experiment more in the future,
or want to open a pull request for code changes.
{{% /notice %}}