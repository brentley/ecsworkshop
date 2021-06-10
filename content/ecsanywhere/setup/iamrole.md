+++
title = "IAM Role"
description = "Use metadata to catalogue and describe your workshop"
weight = 2
+++

## Overview

* In order to manage the instances running on-prem AWS Systems Manager agent will install on customer managed operating systems and turn those operating systems into “managed instances.”
* A new converged version of the existing open source Amazon ECS agent will install on these managed instances (leveraging [SSM Distributor](https://docs.aws.amazon.com/systems-manager/latest/userguide/distributor.html), for example).
* These instances will register into an ECS cluster previously defined in the control plane in the Region.
* So in order for the SSM agent to connect back to ECS control plane, we need to create an IAM role with principal as `ssm.amazon.com` and assign `AmazonSSMManagedInstanceCore` and `AmazonEC2ContainerServiceforEC2Role` policies to it.

Here is the high level description of what each of these policies are responsible for:

<table>
<tr>
<th>
Name
</th>
<th>
Description
</th>
</tr>

<tr>
<td><b>AmazonSSMManagedInstanceCore</b></td>
<td>This required trust policy enables an instance to use Systems Manager core service functionality. It provides minimum permissions which allow the instance to:  <br /><br /> - Register as a managed instance <br /> - Send heartbeat information <br /> - Send and receive messages for Run Command and Session Manager <br /> - Retrieve State Manager association details <br /> - Read parameters in Parameter Store</td>
</tr>

<tr>

<td>
<br/><br/><br/><b>AmazonEC2ContainerServiceforEC2Role</b>
</td>

<td>
This managed policy allows Amazon ECS container instances to make calls to AWS on your behalf.
<pre>
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
</pre>
</td>

</tr>
</table>

## Create IAM roles

Run the following command from the root directory to create role and associate IAM policies required for setting up the ECS-anywhere cluster

```bash
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://ssm-trust-policy.json
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role

# Verify
aws iam list-attached-role-policies --role-name $ROLE_NAME
```
