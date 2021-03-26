---
title: "Inject Secure Parameters"
chapter: false
weight: 34
---

When working with secrets in an AWS infrastructure workload, you have the option to use AWS System Manager Parameter Store.  

AWS Systems Manager Parameter Store provides secure, hierarchical storage for configuration data management and secrets management. You can store data such as passwords, database strings, Amazon Machine Image (AMI) IDs, and license codes as parameter values.

You can store values as plain text or encrypted data. You can reference Systems Manager parameters in your scripts, commands, SSM documents, and configuration and automation workflows by using the unique name that you specified when you created the parameter.

As a best practice, you should generally opt to use Secrets Manager over Parameter store for secure credentials infrequently accessed.

{{%expand "Click here to expand feature comparison" %}}

#### Parameter Store vs Secrets Manager

| Feature | Parameter Store | Secrets Manager |
| ------- | --------------- | --------------- |
| Storage Size | 4kb,8kb| 10kb |
| KMS Encryption | Yes | Yes (supports [CMK](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys) ) |
| Password Generation | No | Yes |
| Secret Rotation | No | Yes |
| Cross Account Access | No | Yes |
| Pricing | [Guide][ssm-pricing-link] | [Guide](https://aws.amazon.com/secrets-manager/pricing/) |
 {{% /expand%}}

{{< tabs >}}
{{< tab name="copilot-cli" include="./copilot.md" />}}
{{< tab name="cdk" include="./cdk.md" />}}
