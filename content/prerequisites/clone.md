+++
title = "Clone your Repos"
chapter = false
weight = 6
+++

Clone your forked repos to your workspace:
{{% notice tip %}}
replace **your_username** with your GitHub username
{{% /notice%}}

```
export YOUR_GITHUB_NAME=your_username
```

```
cd ~/environment
git clone git@github.com:$YOUR_GITHUB_NAME/ecsdemo-platform.git
```
  - confirm the github key fingerprint

```
git clone git@github.com:$YOUR_GITHUB_NAME/ecsdemo-frontend.git
git clone git@github.com:$YOUR_GITHUB_NAME/ecsdemo-nodejs.git
git clone git@github.com:$YOUR_GITHUB_NAME/ecsdemo-crystal.git
```
