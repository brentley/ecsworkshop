+++
title = "Install and Configure Mu"
chapter = false
weight = 20
+++

In the Cloud9 workspace, run the following commands:

```
cd $HOME
wget https://github.com/stelligent/mu/releases/download/v1.5.3/mu-linux-amd64 
chmod +x $HOME/mu-linux-amd64
sudo mv -v $HOME/mu-linux-amd64 /usr/local/bin/mu
```

We should set a namespace so that multiple IAM users can run
this workshop in the same AWS account.

We will pick a random two character string and save it to our environment:

```
export MU_NAMESPACE="mu-$(uuidgen -r | cut -c1-2)"
echo "export MU_NAMESPACE=$MU_NAMESPACE" >> ~/.bashrc
echo "My namespace is $MU_NAMESPACE"
```
