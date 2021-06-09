+++
title = "ECS Tasks"
description = "ECS Tasks"
weight = 1
+++

Part of this chapter we will see how to register a new ECS task and run an workload in the virtual machine

## Register Task

1. Run the following command to create the IAM roles and add the required policies

    ```bash
    # Create the execution role
    aws iam --region $AWS_DEFAULT_REGION create-role --role-name ecsanywhereTaskExecutionRole --assume-role-policy-document file://task-execution-assume-role.json

    # Add the policy to the execution role
    aws iam --region $AWS_DEFAULT_REGION attach-role-policy --role-name ecsanywhereTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

    # Create the task role
    aws iam --region $AWS_DEFAULT_REGION create-role --role-name ecsanywhereTaskRole --assume-role-policy-document file://task-execution-assume-role.json    
    ```

2. Run the following command from root directory to register the ECS Task

    ```bash
    #Register the task definition
    aws ecs register-task-definition --cli-input-json file://external-task-definition.json
    ```

    Below is the snapshot of the registered task definition and the key difference is pointed out as an highlight on `requiresCompatibilities` attribute. Specifying it as `EXTERNAL` will execute this workload in the virtual machine instead of running it in AWS cloud

    {{< highlight json "linenos=false, hl_lines=2-4">}}
    {
    "requiresCompatibilities": [
        "EXTERNAL"
    ],
    "containerDefinitions": [
        {
        "name": "nginx",
        "image": "public.ecr.aws/nginx/nginx:latest",
        "memory": 256,
        "cpu": 256,
        "essential": true,
        "portMappings": [
            {
            "containerPort": 80,
            "hostPort": 8080,
            "protocol": "tcp"
            }
        ]
        }
    ],
    "networkMode": "bridge",
    "family": "nginx"
    }
    {{</highlight>}}

    The task definition registers a container with the following parameters:
    * Image - Nginx web (from ECR public repo)
    * CPU - 256
    * Memory - 256
    * Port - HostPort 8080, Target port 80

3. Execute the following command to run the registered task

    ```bash
    aws ecs run-task --cluster $CLUSTER_NAME --launch-type EXTERNAL --task-definition nginx
    ```

    > It should start the nginx container which can be confirmed in the response with `lastStatus` attribute set as `PENDING`.

4. Run the following command to set the TASKID part of the environment variable

    ```bash
    export TEST_TASKID=$(aws ecs list-tasks --cluster $CLUSTER_NAME | jq -r '.taskArns[0]')
    ```

5. Verify the status of the task by running the following command

    ```bash
    aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TEST_TASKID
    ```

    > `lastStatus` attribute in the response should be set as `RUNNING`, which says the workload has been successfully deployed in the virtual machine

## Verify Task

If running the basic example with NGINX we enabled port forwarding in the Vagrant file.

```bash
    config.vm.network "forwarded_port", guest: 8080, host: 8080
```

We should be able to go to `http://localhost:8080` now and see nginx running locally.

![Nginx](../images/app.png)

## Manage Task

We can use the same AWS ECS CLI command to manage the task running in virtual box

1. Run the following command to stop the task

    ```bash
    aws ecs stop-task --cluster $CLUSTER_NAME --task $TEST_TASKID
    ```

2. Run the following command to list all the tasks running in the ECS cluster to verify the task has been successfully stopped

    ```bash
    aws ecs list-tasks --cluster $CLUSTER_NAME
    ```

    **Output**

    ```json
    {
       "taskArns": []
    }
    ```