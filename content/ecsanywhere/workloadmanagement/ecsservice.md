+++
title = "ECS Service"
description = "ECS Service"
weight = 2
+++

Part of this chapter we will see how to register a new ECS service, setup desired counts and manage the workloads running in the virtual machine

## Register Service

1. Run the following command from root directory to register the ECS Service

    ```bash
    #Create a nginx ECS service
    aws ecs create-service --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --launch-type EXTERNAL --task-definition nginx --desired-count 1
    ```

    > Note: Setting `--launch-type` attribute as `EXTERNAL` will let the ECS control plane to run the underlying tasks in the virtual box instead of AWS environment.

2. Use the same AWS ECS CLI command to describe the ECS service to check the service status

    ```bash
    # Check the service status
    aws ecs describe-services --cluster $CLUSTER_NAME --service $SERVICE_NAME
    ```

    > The command response should have the `status` attribute set to be `ACTIVE`

3. Run the following command to verify the task associated with this service is up and running

    ```bash
    # Verify only 1 tasks is running and it's from the service
    aws ecs list-tasks --cluster $CLUSTER_NAME
    ```

    **Output**

    ```json
    {
        "taskArns": [
            "arn:aws:ecs:us-east-1:775492342640:task/test-ecs-anywhere/f60eecdd542646909d0434f19aa24167"
        ]
    }
    ```

4. Verify whether the underlying nginx application is up and running by to `http://localhost:8080` and seeing the nginx welcome page, like below:

    ![Nginx](../images/app.png)

## Update Desired count

1. We will use the same AWS ECS CLI command to set the number of ECS tasks that needs to be executed

    ```bash
    # Update the service such that the desired count is 0, which allows you to delete it
    aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0
    ```

    > Note: The above command will delete the nginx task thats running

2. Run the following command after couple of seconds you should see an empty array for `taskArns` confirming all the tasks associated with the service has been stopped

    ```bash
    aws ecs list-tasks --cluster $CLUSTER_NAME
    ```

    **Output**

    ```json
    {
        "taskArns": []
    }
    ```

## Delete service

We can use the same AWS ECS CLI command to delete the ECS service, run the following command to do so:

```bash
# Delete the service
aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME
```
