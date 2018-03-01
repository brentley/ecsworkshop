+++
title = "Install and Configure Mu"
chapter = false
weight = 2
+++

In the Cloud9 workspace, run the following commands:

```
curl -s https://getmu.io/install.sh | sudo sh
```

We should set a namespace so that multiple IAM users can run 
this workshop in the same AWS account.

We will pick a random string up to 7 characters and save it to our environment:

```
export MU_NAMESPACE=$(uuidgen -r | cut -c1-5)
echo "export MU_NAMESPACE=$MU_NAMESPACE" >> ~/.bashrc
echo "My namespace is $MU_NAMESPACE"
```