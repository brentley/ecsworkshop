---
title: "Deploy ECS Cluster Auto Scaling (COMING SOON)"
disableToc: true
hidden: true
---
 
### Enable EC2 capacity on the cluster

Navigate back to the repo where we create and manage the platform.

```bash
cd ~/environment/container-demo/cdk
```

In the app.py, uncomment the code under the section of code that says `###### CAPACITY PROVIDERS SECTION #####`. It should look like this:

```python
        ###### CAPACITY PROVIDERS SECTION #####
        # Adding EC2 capacity to the ECS Cluster
        self.asg = self.ecs_cluster.add_capacity(
            "ECSEC2Capacity",
            instance_type=aws_ec2.InstanceType(instance_type_identifier='t3.small'),
            min_capacity=0,
            max_capacity=10
        )
        
        core.CfnOutput(self, "EC2AutoScalingGroupArn", value=self.asg.auto_scaling_group_arn, export_name="EC2ASGArn")
        core.CfnOutput(self, "EC2AutoScalingGroupName", value=self.asg.auto_scaling_group_name, export_name="EC2ASGName")
        ##### END CAPACITY PROVIDER SECTION #####
```

Now, update the cluster using the cdk.

```bash
cdk deploy --require-approval never
```

By adding that small section of code, all of the necessary components to create an EC2 backed cluster will be created. This includes an Auto Scaling Group, Launch Configuration, etc.

Once the deployment is complete, let's move back to the previous repo and start work on setting up cluster auto scaling.

```bash
cd ~/environment/ecsdemo-capacityproviders/ec2
```

### Enable Cluster Auto Scaling

As we did in the previous section, we are going to once again create a capacity provider. This time; however, it will be a capacity provider to enable managed cluster auto scaling. Let's do that now.

```bash
export asg_name=$(aws cloudformation describe-stacks --stack-name ecsworkshop-base | jq -r '.Stacks[].Outputs[] | select(.ExportName | contains("EC2ASGName"))| .OutputValue')
export asg_arn=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $asg_name | jq .AutoScalingGroups[].AutoScalingGroupARN)
aws ecs create-capacity-provider \
     --name EC2BackedCapacity \
     --auto-scaling-group-provider autoScalingGroupArn="$asg_arn",managedScaling=\{status="ENABLED",targetCapacity=80\},managedTerminationProtection="DISABLED" \
     --region us-west-2
```

- In order to create a capacity provider with cluster auto scaling enabled, we need to have an auto scaling group created prior. We did this earlier in this section. We are querying the API via the AWS CLI to get the ARN of the auto scaling group.

- The next command is creating a capacity provider via the AWS CLI. Let's look at the parameters and explain what their purpose:

  - `--name`: This is the human readable name for the capacity provider that we are creating.
  - `--auto-scaling-group-provider`: There is quite a bit here, let's unpack one by one:
  
    - `autoScalingGroupArn`: The ARN of the auto scaling group for the cluster autoscaler to use.
    - `managedScaling`: This is where we enable/disable cluster auto scaling. We also set `targetCapacity`, which determines at what point in cluster utilization do we want the auto scaler to take action.
    - `managedTerminationProtection`: Enable this parameter if you want to ensure that prior to an EC2 instance being terminated (for scale-in actions), the auto scaler will only terminate instances that are not running tasks.

Now that we have a capacity provider created, we need to associate it with the ECS Cluster.

```bash
aws ecs put-cluster-capacity-providers \
--cluster container-demo \
--capacity-providers EC2BackedCapacity \
--default-capacity-provider-strategy capacityProvider=EC2BackedCapacity,weight=1,base=1
```