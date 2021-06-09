+++
title = "Monitoring and Tracing"
description = "Monitoring and Tracing"
weight = 2
+++

For monitoring and Tracing on ECS-A we will be leveragin AWS OTEL and Cloudwatch Container Insights.

AWS Distro for OpenTelemetry Collector(AWS OTel Collector) is a AWS supported version of the upstream OpenTelemetry Collector and is distributed by Amazon. It supports the selected components from the OpenTelemetry community. It is fully compatible with AWS computing platforms including EC2, ECS and EKS. It enables users to send telemetry data to AWS CloudWatch Metrics, Traces and Logs backends as well as the other supported backends.

## Enable Container Insights

```bash
#Enable Container Insights for the Cluster
aws ecs update-cluster-settings --cluster $CLUSTER_NAME --settings name=containerInsights,value=enabled
```

## Lanch the OTEL task

Let's take a look at the OTEL task we are creating to better understand what is going on. There is 4 containers in here

1. OTEL Collector (Responsible for colleting Logs/Metrics/Traces)
2. OTEL Trace sample emitting app
3. NGINX to generate traffic for logs
4. SOCAT to generate STATSD metrics

In reality OTEL has only the need for a single container, we have added 3 extra's to show how OTEL works. 

The main otel task is just this

- Port 2020 is for Xray
- Port 8125 is for StatsD
- Port 4137 is for OTEL
- Region is required Environment Variable since it runs on prem, and can't leverage metadata.

```json
    "containerDefinitions": [
      {
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "/ecs/aws-otel-EC2",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "ecs",
            "awslogs-create-group": "True"
          }
        },
        "portMappings": [
          {
            "hostPort": 2000,
            "protocol": "udp",
            "containerPort": 2000
          },
          {
            "hostPort": 4317,
            "protocol": "tcp",
            "containerPort": 4317
          },
          {
            "hostPort": 8125,
            "protocol": "udp",
            "containerPort": 8125
          }
        ],
        "environment": [
            {
              "name": "AWS_REGION",
              "value": "us-east-1"
            }
        ],
        "command": [
          "--config=/etc/ecs/container-insights/otel-task-metrics-config.yaml"
        ],
        "image": "amazon/aws-otel-collector",
        "name": "aws-otel-collector"
      }
```

```bash
#Register the OTEL task definition
envsubst < otel-task-definition.json > otel-task-definition-replaced.json && aws ecs register-task-definition --cli-input-json file://otel-task-definition-replaced.json && rm otel-task-definition-replaced.json

aws ecs run-task --cluster $CLUSTER_NAME --launch-type EXTERNAL --task-definition aws-otel-EC2
```

Now we check out the information from OTEL

## Monitoring

Here we can take a look at Container insights, and get an overview of our Task map in the cluster, or drill down by task to get detailed monitoring information.

![Insights](../images/insights.png)

![Map](../images/insights-map.png)

![Resources](../images/insights-resources.png)

## Logging

We can check our SOCAT app and see that logs were indeed being shipped here by OTEL

![Otellogs](../images/otel-logs.png)

## Tracing

We can check our trace sampling app to doublecheck that is working as intended. Here we can get a sampling map of our network traffic, and dig into information about services level or individual traces.

![Tracemap](../images/trace-map.png)

![Sample](../images/trace-samples.png)

To stop the task

```bash
TEST_TASKID=$(aws ecs list-tasks --cluster $CLUSTER_NAME | jq -r '.taskArns[0]')
aws ecs stop-task --cluster $CLUSTER_NAME --task $TEST_TASKID
```