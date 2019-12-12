---
title: "Embedded tab content"
disableToc: true
hidden: true
---

```
curl -s https://getmu.io/install.sh | sudo sh
```

We should set a namespace so that multiple IAM users can run
this workshop in the same AWS account.

We will pick a random two character string and save it to our environment:

```
export MU_NAMESPACE="mu-$(uuidgen -r | cut -c1-2)"
echo "export MU_NAMESPACE=$MU_NAMESPACE" >> ~/.bashrc
echo "My namespace is $MU_NAMESPACE"
```