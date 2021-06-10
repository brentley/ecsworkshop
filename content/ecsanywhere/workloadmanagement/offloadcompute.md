+++
title = "Offload Compute"
description = "Offload Compute"
weight = 4
+++

Due to complaince reasons it quite common along customers to use AWS just for storage and configuration purpose and leverage their own data centers for workload processing. Part of this article lets see how we can address this usecase

## Usecase walkthrough

Here is the high level view architecture of the workload that we are going in this chapter

![OfflineWorkload](../images/OfflineWorkload.svg)

**Notes:**

* Lets see create a typical file processing workload, where a input file lands in an S3 bucket
* Lambda function listening to the S3 bucket will invoke an ECS task to process this file
* This ECS task will download the file from S3 to local disk, process it, save the data to a database (in this case dynamodb) and write the output file back to AWS S3
* Only difference here is instead of running the ECS task in AWS cloud we will be running in vargant VM installed on your local laptop

## Pre-requistes

* Setup the environment variables required to build ECS-anywhere cluster and run workloads using the newly created cluster.

{{% notice note %}}
Change the name of the `CLUSTER_NAME` and `SERVICE_NAME` if desired, for running multiple tests.
{{% /notice %}}

```bash
export AWS_DEFAULT_REGION=us-east-1
export ROLE_NAME=ecsMithrilRole
export CLUSTER_NAME=test-ecs-anywhere
export SERVICE_NAME=test-ecs-anywhere-svc
```

> Note: Change the value of `AWS_DEFAULT_REGION` to match the default AWS region.

* ECS cluster is up and running
* Vagrant VM is connected to ECS control plane and has the required network connectivity to access AWS cloud

## Summary

Here is the high level summary of all the steps involved to run this workload:

* Create a ECR repository for lambda function, run `sam build` and `sam deploy` which will take care of creating the lambda function, S3 input bucket with event trigger and Dynamodb table
* Attach the required IAM policies to `ecsanywhereTaskRole` role in order to provide access to the ECS task to access S3 bucket and ECS cluster
* Create a ECR repository for the ECS task, build the file processor module (written in Go) and push the docker image to AWS ECR
* Register a new ECS task

## Step by step instruction

1. Navigate to the root directory and run the following commands to provide execute permissions on the shell scripts

    ```bash
    cd workload-management/s3-trigger-ecs-task
    chmod +x *.sh
    ```

2. Run the following command to setup environment variables required for this workload.

    ```bash
    source ./0-env.sh
    ```

3. Run the following command to create a new ECR repository for AWS Lambda and ECS Task

    ```bash
    ./1-lambda-ecr-repo.sh
    ```

4. Run the following command to trigger a sam build and deploy

    ```bash
    ./2-sam.sh
    ```

    **Output:**

    ```bash
    CloudFormation events from changeset
    ---------------------------------------------------------------------------------------------------------------------
    ResourceStatus                ResourceType                  LogicalResourceId             ResourceStatusReason
    ---------------------------------------------------------------------------------------------------------------------
    CREATE_IN_PROGRESS            AWS::DynamoDB::Table          OrdersTable                   Resource creation Initiated
    CREATE_IN_PROGRESS            AWS::IAM::Role                LambdaECSTaskFunctionRole     Resource creation Initiated
    CREATE_IN_PROGRESS            AWS::DynamoDB::Table          OrdersTable                   -
    CREATE_IN_PROGRESS            AWS::IAM::Role                LambdaECSTaskFunctionRole     -
    CREATE_COMPLETE               AWS::IAM::Role                LambdaECSTaskFunctionRole     -
    CREATE_IN_PROGRESS            AWS::Lambda::Function         LambdaECSTaskFunction         -
    CREATE_IN_PROGRESS            AWS::Lambda::Function         LambdaECSTaskFunction         Resource creation Initiated
    CREATE_COMPLETE               AWS::DynamoDB::Table          OrdersTable                   -
    CREATE_COMPLETE               AWS::Lambda::Function         LambdaECSTaskFunction         -
    CREATE_IN_PROGRESS            AWS::Lambda::Permission       LambdaECSTaskFunctionFilePr   -
                                                                ocessorPermission
    CREATE_IN_PROGRESS            AWS::Lambda::Permission       LambdaECSTaskFunctionFilePr   Resource creation Initiated
                                                                ocessorPermission
    CREATE_COMPLETE               AWS::Lambda::Permission       LambdaECSTaskFunctionFilePr   -
                                                                ocessorPermission
    CREATE_IN_PROGRESS            AWS::S3::Bucket               SrcBucket                     -
    CREATE_IN_PROGRESS            AWS::S3::Bucket               SrcBucket                     Resource creation Initiated
    CREATE_COMPLETE               AWS::S3::Bucket               SrcBucket                     -
    CREATE_COMPLETE               AWS::CloudFormation::Stack    lambda-ecs-task-launcher      -
    ---------------------------------------------------------------------------------------------------------------------

    CloudFormation outputs from deployed stack
    ----------------------------------------------------------------------------------------------------------------------
    Outputs
    ----------------------------------------------------------------------------------------------------------------------
    Key                 Bucket
    Description         S3 Bucket Name
    Value               aws-file-drop-775492342640

    Key                 LambdaECSTaskFunction
    Description         Lambda ECS Task Function ARN
    Value               lambda-ecs-task-launcher-LambdaECSTaskFunction-9DDHeq8ZFQLm
    ----------------------------------------------------------------------------------------------------------------------

    Successfully created/updated stack - lambda-ecs-task-launcher in us-east-1
    ```

5. Run the following command to attach the required IAM policies to the ECS task and execution role

    ```bash
    ./3-ecs-iam-roles.sh
    ```

    > Note: Permissions relates to `Dynamodb`, `S3` and `ECR` policies are attached to the ECS task role

6. Run the following command to build the Go module and push the docker image to ECR repository

    ```bash
    ./4-ecs-ecr-push.sh
    ```

    **Output**

    ```bash
     => [internal] load build definition from Dockerfile                                                               0.0s
    => => transferring dockerfile: 812B                                                                               0.0s
    => [internal] load .dockerignore                                                                                  0.0s
    => => transferring context: 2B                                                                                    0.0s
    => [internal] load metadata for docker.io/library/golang:alpine                                                   0.0s
    => [builder  1/10] FROM docker.io/library/golang:alpine                                                           0.0s
    => [internal] load build context                                                                                  0.0s
    => => transferring context: 32.34kB                                                                               0.0s
    => CACHED [builder  2/10] RUN apk add --no-cache git                                                              0.0s
    => CACHED [builder  3/10] WORKDIR /app/go-sample-app                                                              0.0s
    => CACHED [builder  4/10] COPY go.mod .                                                                           0.0s
    => CACHED [builder  5/10] COPY go.sum .                                                                           0.0s
    => CACHED [builder  6/10] RUN export GOPROXY="direct"                                                             0.0s
    => CACHED [builder  7/10] RUN go env -w GOPRIVATE=*                                                               0.0s
    => CACHED [builder  8/10] RUN go mod download                                                                     0.0s
    => [builder  9/10] COPY . .                                                                                       0.0s
    => [builder 10/10] RUN go build -o ./out/go-sample-app main.go                                                    5.3s
    => CACHED [stage-1 2/5] RUN apk add --no-cache         python3         py3-pip         ca-certificates     && pi  0.0s
    => CACHED [stage-1 3/5] COPY --from=builder /etc/passwd /etc/passwd                                               0.0s
    => CACHED [stage-1 4/5] COPY --from=builder /etc/group /etc/group                                                 0.0s
    => CACHED [stage-1 5/5] COPY --from=builder /app/go-sample-app/out/go-sample-app /main                            0.0s
    => exporting to image                                                                                             0.0s
    => => exporting layers                                                                                            0.0s
    => => writing image sha256:92ea38962483dd1f83946a8560cad301b590d68dd45cb7241608b73ae3367499                       0.0s
    => => naming to docker.io/library/ecs-task-s3-process-repo                                                        0.0s

    Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
    The push refers to repository [775492342640.dkr.ecr.us-east-1.amazonaws.com/ecs-task-s3-process-repo]
    601d8c0995f1: Layer already exists
    391889d77512: Layer already exists
    b878da30d815: Layer already exists
    cab0017af15d: Layer already exists
    a9d40f605488: Layer already exists
    dc27f0c2b863: Layer already exists
    a588deb4bef3: Layer already exists
    224f6b2e3ad2: Layer already exists
    b2d5eeeaba3a: Layer already exists
    latest: digest: sha256:7f627009807327d285f4612b5882ef7d838448c0630fd2b76e43441bddda1217 size: 2202
    3c22fbba908c:s3-trigger-ecs-task harrajag$
    ```

7. Register the ECS task definition which will get triggered when the file gets dropped into the S3 input bucket

    ```bash
    ./5-register-task.sh
    ```

8. Run the following command to copy a sample input file `test.csv` to the input directory. This will automatically trigger the lambda function, which would invoke the ECS task (executed outside AWS cloud) to process the file

    ```bash
    ./6-test.sh
    ```

9. Once the execution of the ECS task completes, we can see both dynamodb and S3 updated with the output data, like below:

    **S3**
    ![s3](../images/s3.png)

    **Dynamodb**
    ![dynamodb](../images/dynamodb.png)

10. Run the following command to cleanup all the resources created part of this article

    ```bash
    ./7-cleanup.sh
    cd ../..
    ```

## Conclusion

This workload demostrates the power of ECS-anywhere, where the customer has the flexibility to pick between AWS cloud and their own data-center.