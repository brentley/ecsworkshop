+++
title = "Install and Configure Mu"
chapter = false
weight = 2
+++

In the Cloud9 workspace, run the following commands:

```
curl -s https://getmu.io/install.sh | sudo sh
```
Since Fargate is currently only in **us-east-1** we will adjust our environment's default region:
```
export AWS_REGION=us-east-1
echo 'export AWS_REGION=us-east-1' >> ~/.bashrc
```
