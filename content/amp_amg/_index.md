---
title: "Monitoring using Amazon Managed Service for Prometheus / Grafana"
chapter: true
weight: 53
---

# Configure Amazon Managed Service for Prometheus / Grafana for your ECS cluster

### Introduction

In this chapter we will learn about setting up Monitoring for the your ECS environment using Amazon Managed Service for Prometheus / Grafana and collecting metrics using AWS Distro for OpenTelemetry.

#### Amazon Managed Service for Prometheus (AMP)

Amazon Managed Service for Prometheus is a monitoring service for metrics compatible with the open source Prometheus project, making it easier for you to securely monitor container environments. AMP is a solution for monitoring containers based on the popular Cloud Native Computing Foundation (CNCF) Prometheus project. AMP is powered by Cortex, an open source CNCF project that adds horizontal scalability to ingest, store, query, and alert on Prometheus metrics. AMP reduces the heavy lifting required to get started with monitoring applications across Amazon Elastic Kubernetes Service and Amazon Elastic Container Service, as well as self-managed Kubernetes clusters. AMP automatically scales as your monitoring needs grow. It offers highly available, multi-Availability Zone deployments, and integrates AWS security and compliance capabilities. AMP offers native support for the PromQL query language as well as over 150+ Prometheus exporters maintained by the open source community.

{{% button href="https://aws.amazon.com/prometheus/faqs/" icon="fab fa-leanpub" icon="fab fa-leanpub" icon-position="right"  %}}Learn more about AMP{{% /button %}}

#### Amazon Managed Service for Grafana (AMG)

Amazon Managed Service for Grafana is a fully managed service with rich, interactive data visualizations to help customers analyze, monitor, and alarm on metrics, logs, and traces across multiple data sources. You can create interactive dashboards and share them with anyone in your organization with an automatically scaled, highly available, and enterprise-secure service. With Amazon Managed Service for Grafana, you can manage user and team access to dashboards across AWS accounts, AWS regions, and data sources. Amazon Managed Service for Grafana provides an intuitive resource discovery experience to help you easily onboard your AWS accounts across multiple regions and securely access AWS services such as Amazon CloudWatch, AWS X-Ray, Amazon Elasticsearch Service, Amazon Timestream, AWS IoT SiteWise, and Amazon Managed Service for Prometheus.

{{% button href="https://aws.amazon.com/grafana/faqs/" icon="fab fa-leanpub" icon="fab fa-leanpub" icon-position="right"  %}}Learn more about AMG{{% /button %}}

#### AWS Distro for OpenTelemetry

AWS Distro for OpenTelemetry is a secure, production-ready, AWS-supported distribution of the OpenTelemetry project. Part of the Cloud Native Computing Foundation, OpenTelemetry provides open source APIs, libraries, and agents to collect distributed traces and metrics for application monitoring.

With AWS Distro for OpenTelemetry, you can instrument your applications just once to send correlated metrics and traces to multiple monitoring solutions. Use auto-instrumentation agents to collect traces without changing your code. AWS Distro for OpenTelemetry also collects metadata from your AWS resources and managed services, so you can correlate application performance data with underlying infrastructure data, reducing the mean time to problem resolution.

Use AWS Distro for OpenTelemetry to instrument your applications running on Amazon Elastic Compute Cloud (EC2), Amazon Elastic Container Service (ECS), and Amazon Elastic Kubernetes Service (EKS) on EC2, and AWS Fargate, as well as on- premises.

{{% button href="https://aws-otel.github.io/docs/introduction/" icon="fab fa-leanpub" icon="fab fa-leanpub" icon-position="right"  %}}Learn more about AWS Distro for OpenTelemetry{{% /button %}}

To learn more about AWS Observability Services and tools please check

{{% button href="https://observability.workshop.aws" icon="fab fa-leanpub" icon="fab fa-leanpub" icon-position="right"  %}}AWS Observability Workshop{{% /button %}}
