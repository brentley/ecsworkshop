---
title: "Deploy an EC2 Spot Capacity Provider"
disableToc: true
hidden: true
---

### EC2 Spot Instances 

[Amazon EC2 Spot Instances](https://aws.amazon.com/ec2/spot/) are spare EC2 capacity offered with an up to 90% discount compared to On-Demand pricing. Spot Instances enable you to optimize your costs on the AWS cloud and scale your application’s throughput up to 10X for the same budget. Spot Instances can be interrupted with a two minutes warning when EC2 needs the capacity back. 

Containerized workloads are often stateless and fault tolerant, which makes them a very good fit to run on Spot Instances. The Amazon ECS agent can be configured to automatically catch the Spot Instance interruption notices, so if an instance is going to be interrupted, it is set to `DRAINING`. When a container instance is set to `DRAINING`, Amazon ECS prevents new tasks from being scheduled for placement on the container instance. Service tasks on the container instance that are in the `RUNNING` state are stopped and replaced according to the service's deployment configuration parameters, `minimumHealthyPercent` and `maximumPercent`. For more information, check out the [Container instance draining](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-draining.html) and the [using Spot Instances](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-spot.html) documentation.

A key best practice to successfully use Spot instances is to be **instance type flexible** so you can acquire capacity from multiple Spot capacity pools for scaling and replacing interrupted Spot instances. A Spot capacity pool is a set of unused EC2 instances with the same instance type (e.g. m5.large), operating system and availability zone. This best practice is very simple to achieve with EC2 Auto Scaling groups, which allow you to [combine multiple instance types and purchase options](https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-purchase-options.html). By using the `capacity-optimized` *SpotAllocationStrategy* Auto Scaling launches instances from the pools with optimal capacity, reducing the likelihood of interruptions. To learn more about `capacity-optimized` check out [this blog post](https://aws.amazon.com/blogs/aws/capacity-optimized-spot-instance-allocation-in-action-at-mobileye-and-skyscanner/).

### Enable EC2 Spot capacity on the cluster

Navigate back to the repo where we create and manage the platform.

```bash
cd ~/environment/container-demo/cdk
```

In the app.py, uncomment the code under the section of code that says `###### EC2 SPOT CAPACITY PROVIDER SECTION ######`. It should look like this:

```python
        ##### EC2 SPOT CAPACITY PROVIDER SECTION ######
        # As of today, AWS CDK doesn't support Launch Templates on the AutoScaling construct, hence it
        # doesn't support Mixed Instances Policy to combine instance types on Auto Scaling and adhere to Spot best practices
        # In the meantime, CfnLaunchTemplate and CfnAutoScalingGroup resources are used to configure Spot capacity
        # https://github.com/aws/aws-cdk/issues/6734

        self.ecs_spot_instance_role = aws_iam.Role(
            self, "ECSSpotECSInstanceRole",
            assumed_by=aws_iam.ServicePrincipal("ec2.amazonaws.com"),
            managed_policies=[
                aws_iam.ManagedPolicy.from_aws_managed_policy_name("service-role/AmazonEC2ContainerServiceforEC2Role"),
                aws_iam.ManagedPolicy.from_aws_managed_policy_name("service-role/AmazonEC2RoleforSSM")
                ]
        )
                #
        self.ecs_spot_instance_profile = aws_iam.CfnInstanceProfile(
            self, "ECSSpotInstanceProfile",
            roles = [
                    self.ecs_spot_instance_role.role_name
                ]
            )
                
        # This creates a Launch Template for the Auto Scaling group
        self.lt = aws_ec2.CfnLaunchTemplate(
            self, "ECSEC2SpotCapacityLaunchTemplate",
            launch_template_data={
                "instanceType": "m5.large",
                "imageId": aws_ssm.StringParameter.value_for_string_parameter(
                            self,
                            "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"),
                "securityGroupIds": [ x.security_group_id for x in self.ecs_cluster.connections.security_groups ],
                "iamInstanceProfile": {"arn": self.ecs_spot_instance_profile.attr_arn},

                # Here we configure the ECS agent to drain Spot Instances upon catching a Spot Interruption notice from instance metadata
                "userData": core.Fn.base64(
                    core.Fn.sub(
                        "#!/usr/bin/bash\n"
                        "echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config\n" 
                        "sudo iptables --insert FORWARD 1 --in-interface docker+ --destination 169.254.169.254/32 --jump DROP\n"
                        "sudo service iptables save\n"
                        "echo ECS_ENABLE_SPOT_INSTANCE_DRAINING=true >> /etc/ecs/ecs.config\n" 
                        "echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config\n"  
                        "cat /etc/ecs/ecs.config",
                        variables = {
                            "cluster_name":self.ecs_cluster.cluster_name
                            }
                        )
                    )
                },
                launch_template_name="ECSEC2SpotCapacityLaunchTemplate")

        self.ecs_ec2_spot_mig_asg = aws_autoscaling.CfnAutoScalingGroup(
            self, "ECSEC2SpotCapacity",
            min_size = "0",
            max_size = "10",
            vpc_zone_identifier = [ x.subnet_id for x in self.vpc.private_subnets ],
            mixed_instances_policy = {
                "instancesDistribution": {
                    "onDemandAllocationStrategy": "prioritized",
                    "onDemandBaseCapacity": 0,
                    "onDemandPercentageAboveCapacity": 0,
                    "spotAllocationStrategy": "capacity-optimized"
                    },
                "launchTemplate": {
                    "launchTemplateSpecification": {
                        "launchTemplateId": self.lt.ref,
                        "version": self.lt.attr_default_version_number
                    },
                    "overrides": [
                        {"instanceType": "m5.large"},
                        {"instanceType": "m5d.large"},
                        {"instanceType": "m5a.large"},
                        {"instanceType": "m5ad.large"},
                        {"instanceType": "m5n.large"},
                        {"instanceType": "m5dn.large"},
                        {"instanceType": "m3.large"},
                        {"instanceType": "m4.large"},
                        {"instanceType": "t3.large"},
                        {"instanceType": "t2.large"}
                    ]
                }
            }
        )
                
        core.Tag.add(self.ecs_ec2_spot_mig_asg, "Name", self.ecs_ec2_spot_mig_asg.node.path)   
        core.CfnOutput(self, "EC2SpotAutoScalingGroupName", value=self.ecs_ec2_spot_mig_asg.ref, export_name="EC2SpotASGName")     
```

Now, update the cluster using the cdk.

```bash
cdk deploy --require-approval never
```

By adding that section of code, all of the necessary components to add EC2 Spot instances to the cluster will be created. This includes an Auto Scaling Group with mixed instance types, Launch Template, ECS Optimized AMI, etc. Let's break down the important pieces:
- Notice we are creating a [Launch Template](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html). This is required to combine instance types and purchase options on an Auto Scaling group.
- On the User Data of the launch template, we're configuring the ECS agent to drain a Spot Container Instance when receiving an interruption notice: `ECS_ENABLE_SPOT_INSTANCE_DRAINING=true`.
- On the Auto Scaling group, we're defining a Mixed Instances Policy. On instance distribution, we're setting up the Auto Scaling group to launch only EC2 Spot Instances and use the `capacity-optimized` Spot Allocation Strategy. This makes Auto Scaling launch instances from the Spot capacity pool with optimal capacity for the number or instances that are launching. Deploying this way helps you make the most efficient use of spare EC2 capacity and reduce the likelihood of interruptions.
- On the `overrides` section, we're configuring 10 different instance types that we can use on our ECS cluster. Multipliying this number by the number of Availability Zones in use will give us the number of Spot capacity pools we can launch capacity from ( e.g. if we're across 3 AZs, it means we can get capacity from 30 different Spot capacity pools). This maximizes our ability acquire the required Spot capacity (the more pools the better). 

Once the deployment is complete, let's move back to the capacity provider demo repo and start work on setting up cluster auto scaling.

```bash
cd ~/environment/ecsdemo-capacityproviders/ec2
```

### Enable Cluster Auto Scaling

As we did in the previous section, we are going to once again create a capacity provider, this time for the Spot Instances Auto Scaling group we just created. We'll also enable managed cluster autoscaling on it. Let's do that now.

```bash
# Get the required cluster values needed when creating the capacity provider
export spot_asg_name=$(aws cloudformation describe-stacks --stack-name ecsworkshop-base --query 'Stacks[*].Outputs[?ExportName==`EC2SpotASGName`].OutputValue' --output text)
export spot_asg_arn=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $spot_asg_name --query 'AutoScalingGroups[].AutoScalingGroupARN' --output text)
export spot_capacity_provider_name=$(echo "EC2Spot$(date +'%s')")
# Creating capacity provider
aws ecs create-capacity-provider \
     --name $spot_capacity_provider_name \
     --auto-scaling-group-provider autoScalingGroupArn="$spot_asg_arn",managedScaling=\{status="ENABLED",targetCapacity=80\},managedTerminationProtection="DISABLED" \
     --region $AWS_REGION
```

- In order to create a capacity provider with cluster auto scaling enabled, we need to have an auto scaling group created prior. We did this earlier in this section when we added the EC2 Spot capacity to the ECS cluster. We run a couple of cli calls to get the Auto Scaling group details which is required for the next command where we create the capacity provider.

- The next command is creating a capacity provider via the AWS CLI. Let's look at the parameters and explain what their purpose:

  - `--name`: This is the human readable name for the capacity provider that we are creating.
  - `--auto-scaling-group-provider`: There is quite a bit here, let's unpack one by one:
  
    - `autoScalingGroupArn`: The ARN of the auto scaling group for the cluster autoscaler to use.
    - `managedScaling`: This is where we enable/disable cluster auto scaling. We also set `targetCapacity`, which determines at what point in cluster utilization do we want the auto scaler to take action.
    - `managedTerminationProtection`: Enable this parameter if you want to ensure that prior to an EC2 instance being terminated (for scale-in actions), the auto scaler will only terminate instances that are not running tasks.

Now that we have a new capacity provider created, we need to associate it with the ECS Cluster. As we created an On-Demand Auto Scaling capacity provider on the previous section, we'll add the Spot Auto Scaling capacity provider to the cluster and assign both capacity providers the same weight on the cluster default capacity provider strategy, with a base of 1 initial task scheduled on the On-Demand capacity provider. With this configuration, the first task will be scheduled on the On-Demand capacity provider. Subsequent tasks will be scheduled 50% on the Spot Auto Scaling capacity provider and the other 50% on the On-Demand Auto Scaling capacity provider.  

```bash
aws ecs put-cluster-capacity-providers \
--cluster container-demo \
--capacity-providers $capacity_provider_name $spot_capacity_provider_name \
--default-capacity-provider-strategy capacityProvider=$capacity_provider_name,weight=1,base=1 capacityProvider=$spot_capacity_provider_name,weight=1,base=0
```

You will get a json response indicating that the cluster update has been applied. 

Wait for a couple of minutes until cluster autoscaling utilization metric of the new capacity provider is triggered and the Spot Auto Scaling group is scaled out. 

If you go back to the ECS console and select the `container-demo` cluster, you will see the new Capacity provider on the `CapacityProviders` tab. If you go to the `ECS Instances` tab, you will see that we now have 4 EC2 instances, 2 of each Capacity provider. This is because we have specified an 80% as target capacity on Cluster Auto Scaling so we allow some room for new tasks to be scheduled without needing to wait for new instances to come up. It's a best practice to overprovision your cluster a bit to allow faster task scaling and faster launch of task replacements when a Spot Instance is interrupted. If you don't want to leave any extra room, you can adjust the `targetCapacity` value to 100.

![ecsdemo-cluster-registered-instances](/images/ecs-container-demo-registered-instances.png)

You can check to what Capacity Provider each instance belongs with the following CLI commands:

```bash
aws ecs describe-container-instances --cluster container-demo  \
                --container-instances $(aws ecs list-container-instances \
                                        --cluster container-demo \
                                        --query 'containerInstanceArns[]' \
                                        --output text) \
                --query 'containerInstances[].{InstanceId: ec2InstanceId, 
                                                CapacityProvider: capacityProviderName, 
                                                RunningTasks: runningTasksCount}' \
                --output table
```

The output will be similar to the following:

```
--------------------------------------------------------------
|                 DescribeContainerInstances                 |
+-------------------+-----------------------+----------------+
| CapacityProvider  |      InstanceId       | RunningTasks   |
+-------------------+-----------------------+----------------+
|  EC21601113073    |  i-06792f1c7815de3de  |  0             |
|  EC2Spot1601114241|  i-008a88877716d2659  |  0             |
|  EC2Spot1601114241|  i-0cb525a7402d3cb6a  |  0             |
|  EC21601113073    |  i-060dc25c0b3877faa  |  1             |
+-------------------+-----------------------+----------------+
```

### Redeploy the EC2 backed ECS service

Even though we have updated the cluster default capacity provider strategy, it will only apply to new services with no specified strategy. This means our service is still using the previous strategy. To update the capacity providers strategy of the service, we'll need to update the service and redeploy it. 

On the Amazon ECS console go to the `container-demo` cluster and on the `Services` tab, click on the `ecsdemo-capacityproviders-ec2` service.

![ecsdemo-capacity-providers-ec2-service](/images/ecsdemo-capacityproviders-ec2-service.png)

Now, let's update the service capacity provider strategy to match the cluster default capacity providers strategy. Click on the `Update` button on the top-right corner, and on the configure service, on the `Capacity provider strategy` click `Add another provider`. Then, on the `Provider 2` drop-down menu select the capacity provider we created before `EC2Spot*`. Leave the `Force new deployment` checkbox marked to redeploy the service so the new strategy takes effect. Then, scroll to the very bottom of the screen, click on `Skip to review` and on the new screen click on the `Update Service` button at the very bottom. Then click on `View Service` to go back to the ECS Service console. 

![ecsdemo-capacity-providers-ec2-service-update-strategy](/images/update-ecsdemo-capacityproviders-ec2-service-strategy.png)

Wait for a few minutes while the service is re-deployed. You can monitor it on the `Deployments` tab.

![service-deployment](/images/ecsdemo-capacityproviders-ec2-service-deployment.png)

### Scale the service beyond the current capacity available

Now we can scale out again our service. ECS will adhere to the capacity providers strategy we just configured: one base task on the On-Demand Auto Scaling Capacity provider and then 50% of the tasks on the Spot Auto Scaling capacity provider and the other 50% on the On-Demand capacity provider.

Go to the deployment configuration (`~/environment/ecsdemo-capacityproviders/ec2/app.py`), and do the following:

Change the desired_count parameter from `1` to `20`.

```python
        self.load_balanced_service = aws_ecs_patterns.ApplicationLoadBalancedEc2Service(
            self, "EC2CapacityProviderService",
            service_name='ecsdemo-capacityproviders-ec2',
            cluster=self.base_platform.ecs_cluster,
            cpu=256,
            memory_limit_mib=512,
            #desired_count=1,
            desired_count=20,
            public_load_balancer=True,
            task_image_options=self.task_image,
        )
```

Now, save the changes, and let's deploy.

```bash
cdk deploy --require-approval never
```

Let's walk through what we did and what is happening.

- We are modifying our task count for the service to go from one, to twenty. This will stretch us beyond the capacity that presently exists for the cluster on both capacity providers.
- The capacity providers used by the service will recognize that the target capacity of each of them is above 80%. This will trigger a autoscaling events to scale capacity of the underlying auto scaling groups back to 80% or under.
- The EC2 Spot Auto Scaling group will scale out selecting the instance types on each AZ optimal based on the spare capacity availability of each pool at launch time. 

If you navigate to the ECS console you will notice there're 20 tasks attempting to run:

![cp-spot-20tasks](/images/cp_spot_20_tasks.png)

As we're using multiple capacity providers, for simplicity, this time we will monitor the tasks using the AWS CLI. To check the state of the tasks run the following command:

```bash 
aws ecs describe-tasks --cluster container-demo \
                       --tasks \
                         $(aws ecs list-tasks --cluster container-demo --query 'taskArns[]' --output text) \
                       --query 'sort_by(tasks,&capacityProviderName)[].{ 
                                          Id: taskArn, 
                                          AZ: availabilityZone, 
                                          CapacityProvider: capacityProviderName, 
                                          LastStatus: lastStatus, 
                                          DesiredStatus: desiredStatus}' \
                        --output table
```

Wait for a few minutes while Cluster Auto Scaler scales out the Auto Scaling groups and all the pending tasks are scheduled and RUNNING. The output will be similar to the following:

```
---------------------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                        DescribeTasks                                                                        |
+------------+--------------------+----------------+-------------------------------------------------------------------------------------------+--------------+
|     AZ     | CapacityProvider   | DesiredStatus  |                                            Id                                             | LastStatus   |
+------------+--------------------+----------------+-------------------------------------------------------------------------------------------+--------------+
|  eu-west-1a|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/14b6752dc2aa4ca48b182a73b2816404  |  RUNNING     |
|  eu-west-1c|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/28617be76d01429691402104d2aeafea  |  RUNNING     |
|  eu-west-1b|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/6582bdd94e844d1fa8c96917d377eb7f  |  RUNNING     |
|  eu-west-1b|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/836e419e903d4c579ef738b276758984  |  RUNNING     |
|  eu-west-1b|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/995b56491ba348a1ae960aba39a0aa17  |  RUNNING     |
|  eu-west-1c|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/9c44823359634a61b6d7b10d965b404c  |  RUNNING     |
|  eu-west-1c|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/b4feaa043c614eb4806e017278bfd144  |  RUNNING     |
|  eu-west-1a|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/ba5935b59dea40afb74712bec6199bb1  |  RUNNING     |
|  eu-west-1b|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/c8dbc59de0c34a1ebf949f33e930979f  |  RUNNING     |
|  eu-west-1b|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/d6955f0489f74a1d8b325f02cad70ae9  |  RUNNING     |
|  eu-west-1a|  EC21601113073     |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/d7353eef77934372b7944ef30f0b4c26  |  RUNNING     |
|  eu-west-1a|  EC2Spot1601114241 |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/12d64f8862a24adb9fc3bb0088a3a3e0  |  RUNNING     |
|  eu-west-1a|  EC2Spot1601114241 |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/16f74b3b019e49edb0489c614daa4137  |  RUNNING     |
|  eu-west-1a|  EC2Spot1601114241 |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/30cfd1d72cc94929ae0ca1410741ae38  |  RUNNING     |
|  eu-west-1c|  EC2Spot1601114241 |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/392abfd8c60743dc8fc2914a443f049a  |  RUNNING     |
|  eu-west-1a|  EC2Spot1601114241 |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/4455122b17944d28b47ac5550660260f  |  RUNNING     |
|  eu-west-1a|  EC2Spot1601114241 |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/5451e0df1d2a4506ae0a0c99ede9ede0  |  RUNNING     |
|  eu-west-1a|  EC2Spot1601114241 |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/bd465054570f4b7b97a319e552706ac3  |  RUNNING     |
|  eu-west-1a|  EC2Spot1601114241 |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/c9accad1e2aa414892863d76fef0b234  |  RUNNING     |
|  eu-west-1a|  EC2Spot1601114241 |  RUNNING       |  arn:aws:ecs:eu-west-1:012345678910:task/container-demo/dc801f7d5f6c4b5e96ea856b2b980d3d  |  RUNNING     |
+------------+--------------------+----------------+-------------------------------------------------------------------------------------------+--------------+
```

Notice that, as configured on the strategy, out of the `20` tasks, 1 base task has been scheduled on the On-Demand Auto Scaling capacity provider, 10 more tasks have been scheduled on the same provider and the other 9 have been scheduled on the Spot Auto Scaling capacity provider. 

Go to the [EC2 Auto Scaling console](https://console.aws.amazon.com/ec2autoscaling/home) and open the `ecsworkshop-base-ECSEC2SpotCapacity-*`. On the `Instance management` tab, check out which instance types Auto Scaling group has launched. The instance types depend on what the optimal Spot pools are at the time your instances are launched. 

![SpotASGInstances](/images/ec2-spot-cp-asg.png)

You can review the mixed instance types policy we've configured before on the `Details` tab and scrolling-down to `Purchase options and instance types`.

![SpotASGMixedInstancesPolicy](/images/ec2-spot-cp-mixed-instances.png)

#### Handling Spot Instance Interruptions

We've configured the ECS agent to set a Spot container instance in `DRAINING` upon receiving an interruption notice by enabling the `ECS_ENABLE_SPOT_INSTANCE_DRAINING=true` flag on the agent configuration file. When an instance is set to `DRAINING`, for the tasks configured behind an Application Load Balancer, ALB will stop sending new requests to the to-be-interrupted tasks and allow the time configured on the `deregistration_delay.timeout_seconds` configured on the ALB Target Group for the in-flight requests to finish. As a Spot instance is interrupted with a 120 seconds notice, we have configured this value to be 90 seconds. 

At the same time, ECS will start replacement tasks for the tasks running on the to-be-interrupted instance. As we have configured 80% as `targetCapacity` on Cluster auto scaling, the replacement tasks that fit on the remaining space on the cluster will be scheduled and started soon. Ideally we want these tasks to be considered `healthy` by the ALB fast, so we have configured the `healthy_threshold_count=2`. With default settings, health checks are evaluated every 30 seconds . This means that it will take at least 1 minute with two successful consecutive health checks for the new tasks to be healthy and start handling traffic.  

If there are additional tasks `PENDING` waiting for EC2 capacity to be scheduled, cluster auto scaling will trigger a scale out action as the target is over 80%.

Take your time to review the configuration on `~/environment/ecsdemo-capacityproviders/ec2/app.py`:

```python
self.cfn_target_group.target_group_attributes = [{ "key" : "deregistration_delay.timeout_seconds", "value": "90" }]
self.cfn_target_group.healthy_threshold_count = 2
```

You can see an example of the flow on the image below.

![ecs-connection-draining](/images/ecs-connection-draining.png)

- On the three events starting from the bottom, you can see how upon `DRAINING` ECS deregisters the 3 targets that were running on the instance from the Target group. This action starts connection draining from the load balancer and also creates 3 replacement task.
- Around 13 seconds later, the new tasks are `RUNNING` and registered to the target group, which will start performing health checks until the healthy_threshold_count (2 in our case) is passed.
- 90 seconds after connection draining started, the tasks running on the to-be-interrupted instance are stopped as connection draining is complete.
- Before completing 2 minutes after setting the instance to `DRAINING`, the ECS service reaches a steady state

You can reproduce this yourself by manually draining an instance on the ECS Console, within containers-demo cluster, by going to the `ECS instances` tab, selecting one instance and clicking `Actions` --> `Drain instances`.


### Scale the service back down to one

Now that we've seen the capacity provider strategy in action, let's drop the count back to one and watch as it will scale our infrastructure back in.

Go back into the deployment configuration (`~/environment/ecsdemo-capacityproviders/ec2/app.py`), and do the following:

Change the desired_count parameter from `20` to `1`.

```python
        self.load_balanced_service = aws_ecs_patterns.ApplicationLoadBalancedEc2Service(
            self, "EC2CapacityProviderService",
            service_name='ecsdemo-capacityproviders-ec2',
            cluster=self.base_platform.ecs_cluster,
            cpu=256,
            memory_limit_mib=512,
            desired_count=1,
            #desired_count=20,
            public_load_balancer=True,
            task_image_options=self.task_image,
        )
```

Now, save the changes, and let's deploy.

```bash
cdk deploy --require-approval never
```

That's it. Now, over the course of the next few minutes,  cluster auto scaling will recognize that we are well above capacity requirements on both capacity providers, and will scale the EC2 instances back in.


#### Cleanup

Run the cdk command to delete the service (and dependent components) that we deployed.

```bash
cdk destroy -f
```

Next, go back to the ECS Cluster in the console. In the top right, select `Update Cluster`.

![updatecluster](/images/cp_update_cluster.png)

Under `Default capacity provider strategy`, click the `x` next to all of the strategies until there are no more left to remove. Once you've done that, click `Update`.

![deletecapprovider](/images/cp_delete_default.png)