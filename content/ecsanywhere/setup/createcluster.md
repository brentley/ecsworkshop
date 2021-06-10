+++
title = "Create ECS cluster"
description = "Pre-requiste steps for setting up and running workloads in ECS-A"
weight = 3
+++

## Create ECS Anywhere Cluster

{{% notice note %}}
Before proceeding to next step make sure the AWS account used for this workshop has ECS anywhere enabled. If not reach out to your AWS TAM (Technical account manager) who can help you with this
{{% /notice %}}

1. Run the following command to create a ECS cluster

    ```bash
    # Create ECS Cluster
    aws ecs create-cluster --cluster-name $CLUSTER_NAME
    ```

2. Below command will create an ECS-anywhere activation key and write it to `ssm-activation.json` in your current working directory

    ```bash
    # Create activation Key
    aws ssm create-activation --iam-role $ROLE_NAME | tee ssm-activation.json
    ```

3. Run the following command to verify the generated activatio

    ```bash
    cat ssm-activation.json
    ```

    ```json
    {
        "ActivationId": "<<ACTIVATIONID>>",
        "ActivationCode": "<<ACTIVATIONCODE>>"
    }
    ```

    > Note: This activation key will help to associate the virtual machine to ECS control plane
