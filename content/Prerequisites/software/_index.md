+++
title = "Install and Configure Mu"
chapter = false
weight = 4
+++

Run:
```shell
curl -s https://getmu.io/install.sh | sudo sh
```
Since Fargate is currently only in **us-east-1** we will adjust our environment's default region:
```shell
export AWS_REGION=us-east-1
```
