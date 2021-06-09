---
title: "Cleanup"
chapter: true
pre: '<i class="fa fa-film" aria-hidden="true"></i> '
weight: 50
---

# Cleanup

1. Run the following command to cleanup the SSM instances

    ```bash
    # Cleanup SSM
    aws ssm describe-activations | jq ".ActivationList | .[] | .ActivationId" | xargs -L 1 aws ssm delete-activation --activation-id
    aws ssm describe-instance-information | jq ".InstanceInformationList | .[] | .InstanceId" | grep "mi-" | xargs -L 1 aws ssm deregister-managed-instance --instance-id
    ```

2. Run the following command to cleanup ECS resources

    ```bash
    # Cleanup ECS resources
    aws ecs list-container-instances --cluster $CLUSTER_NAME | jq ".containerInstanceArns | .[]" | xargs -L 1 aws ecs deregister-container-instance --cluster $CLUSTER_NAME --force --container-instance

    aws ecs delete-cluster --cluster $CLUSTER_NAME
    ```

3. Run the command to verify the deletion of all the items

    ```bash
    # Verify all items deleted are empty
    aws ssm describe-activations
    aws ssm describe-instance-information
    aws ecs list-container-instances --cluster $CLUSTER_NAME
    ```

    **Output**

    ```bash
    # aws ssm describe-activations
    {
        "ActivationList": []
    }

    # aws ssm describe-instance-information
    {
        "InstanceInformationList": []
    }
    
    # aws ecs list-container-instances --cluster $CLUSTER_NAME
    {
        "containerInstanceArns": []
    }
    ```

4. Run the following command to delete the vagrant VM

    ```bash
    #Remove vagrant VM
    vagrant halt
    vagrant destroy
    ```
