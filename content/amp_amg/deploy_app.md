+++
title = "Deploy sample application"
chapter = false
weight = 8
+++

In this chapter we will enable Prometheus metrics collection from an ECS cluster. In this scenario, we will use the Prometheus Receiver to scrape from application and the AWS ECS Container Metrics Receiver to scrape infrastructure metrics.

We will deploy sample app which has ADOT Collector and a Prometheus metric emitter.

Our ADOT Collector configuration will contain two pipelines:

- To scrape application metrics, we will configure the Prometheus Receiver to scrape application metrics from static hosts and export our metrics using the AWS Prometheus Remote Write Exporter.
- To scrape ECS Metrics, we will configure the AWS ECS Container Metrics Receiver to collect ECS metrics and another AWS Prometheus Remote Write Exporter to export metrics.


In the Cloud9 workspace, run the following commands:

#### Clone sample application repo

```bash
cd ~/environment
git clone https://github.com/aws-samples/ecsdemo-amp.git
```

#### Set environment variables to get AMP Remote Write Endpoint created in previous step and add it to ADOT config file

```bash
cd ~/environment/ecsdemo-amp/cdk

export AMP_WORKSPACE_ID=$(aws amp list-workspaces --query 'workspaces[*].workspaceId' --output text)
export AMP_Prometheus_Endpoint=$(aws amp describe-workspace --workspace-id $AMP_WORKSPACE_ID --query 'workspace.prometheusEndpoint' --output text)
export AMP_Prometheus_Remote_Write_Endpoint='"'${AMP_Prometheus_Endpoint}api/v1/remote_write'"'

sed -i -e "s~{{endpoint}}~$AMP_Prometheus_Remote_Write_Endpoint~" ecs-fargate-adot-config.yaml
sed -i -e "s~{{region}}~$AWS_REGION~" ecs-fargate-adot-config.yaml
```


#### Confirm that the cdk can synthesize the assembly CloudFormation templates

```bash
cdk synth
```

#### Review what the cdk is proposing to build and/or change in the environment

```bash
cdk diff
```

## Deploy sample application
```bash
cdk deploy --require-approval never
```