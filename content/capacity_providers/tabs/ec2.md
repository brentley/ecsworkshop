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