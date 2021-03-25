---
title: "AWS Secrets Manager Overview"
chapter: false
weight: 10
---


AWS Secrets Manager helps you protect secrets needed to access your applications, services, and IT resources. The service enables you to easily rotate, manage, and retrieve database credentials, API keys, and other secrets throughout their lifecycle. Users and applications retrieve secrets with a call to Secrets Manager APIs, eliminating the need to hard-code sensitive information in plain text. Secrets Manager offers secret rotation with built-in integration for Amazon RDS, Amazon Redshift, and Amazon DocumentDB. Also, the service is extensible to other types of secrets, including API keys and OAuth tokens. In addition, Secrets Manager enables you to control access to secrets using fine-grained permissions and audit secret rotation centrally for resources in the AWS Cloud, third-party services, and on-premises.

Secrets Manager stores, retrieves, rotates, encrypts and monitors the use of secrets within your application. Secrets Manager uses AWS KMS for encryption with IAM roles to restrict access to the services and CloudTrial for recording the API calls made for secrets.   You can also use your own customer-managed key (CMK) with AWS Secrets Manager.

This tutorial will demonstrate using AWS Secrets Manager with ECS Fargate.  

Here is a diagram of the infrastructure we are going to build:
{{< figure src="/images/secrets-overview.png" alt="Secrets Diagram" width="1200px" >}}

When incoming web traffic passes through the load balancer to our ECS Cluster, the application running in the container reads environment variables that contain the sensitive content.  In this example the sensitive content is credentials for connecting the container app to the RDS instance.  The environment variables are populated by Secrets Manager when the service is started.   Secrets are managed with both security in transit and at rest.  Credential rotation can be configured within Secrets Manager, eliminating the need for custom code within your application.
