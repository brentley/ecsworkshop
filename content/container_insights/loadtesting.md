---
title: "Setup Load testing"
chapter: false
weight: 30
---

#### Preparing your Load Test

We now have monitoring enabled for the ECS environment. Let's go ahead and induce manual load to the environment to see how the metrics are shown using Containe Insights

#### Install Siege for load testing on your Cloud9 Workspace

Download Siege by running the below command in your Cloud9 terminal.

```
curl -C - -O http://download.joedog.org/siege/siege-latest.tar.gz
```
Once downloaded we’ll extract this file and change to the extracted directory. The version may change but you can see the directory name created via the output of the tar command.

```
tar -xvf siege-latest.tar.gz
```
Go to the directory where Seige is downloaded (change for version installed)

```
cd siege-4.0.4
```

```
./configure
make all
sudo make install 
```
Verify Siege is working by typing the below into your terminal window.

```
siege --version
```

![Cluster Dashboard](/images/ContainerInsights14.png)


