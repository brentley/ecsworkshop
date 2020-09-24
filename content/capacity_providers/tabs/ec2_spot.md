---
title: "Deploy an EC2 Spot Capacity Provider"
disableToc: true
hidden: true
---

### EC2 Spot Instances 

[Amazon EC2 Spot Instances](https://aws.amazon.com/ec2/spot/) are spare EC2 capacity offered with an up to 90% discount compared to On-Demand pricing. Spot Instances enable you to optimize your costs on the AWS cloud and scale your application’s throughput up to 10X for the same budget. Spot Instances can be interrupted with a two minutes warning when EC2 needs the capacity back. 

Containerized workloads are often stateless and fault tolerant, which makes them a very good fit to run on Spot Instances. The ECS agent can be configured to automatically catch the Spot Instance interruption notices, so if an instance is going to be interrupted, it is set to `DRAINING`. When a container instance is set to `DRAINING`, Amazon ECS prevents new tasks from being scheduled for placement on the container instance. Service tasks on the container instance that are in the `RUNNING` state are stopped and replaced according to the service's deployment configuration parameters, `minimumHealthyPercent` and `maximumPercent`. For more information, check out the [Container instance draining](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-draining.html) and the [using Spot Instances](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-spot.html) documentation.

A key best practice to successfully use Spot instances is to be **instance type flexible** so you can acquire capacity from multiple Spot capacity pools for scaling and replacing interrupted Spot instances. A Spot capacity pool is a set of unused EC2 instances with the same instance type (e.g. m5.large), operating system and availability zone. This best practice is very simple to achieve with EC2 Auto Scaling groups, which allow you to [combine multiple instance types and purchase options](https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-purchase-options.html). 

### Enable EC2 capacity on the cluster

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
                #
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
                #
        core.Tag.add(self.ecs_ec2_spot_mig_asg, "Name", self.ecs_ec2_spot_mig_asg.node.path)        
```

Now, update the cluster using the cdk.

```bash
cdk deploy --require-approval never
```

By adding that section of code, all of the necessary components to add EC2 Spot instances to the cluster will be created. This includes an Auto Scaling Group, Launch Template, ECS Optimized AMI, etc. Let's break down the important pieces:
- Notice we are creating a [Launch Template](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html). This is required to combine instance types and purchase options on an Auto Scaling group.
- On the User Data of the launch template, we're configuring the ECS agent to drain a Spot Container Instance when receiving an interruption notice: `ECS_ENABLE_SPOT_INSTANCE_DRAINING=true`.
- On the Auto Scaling group, we're defining a Mixed Instances Policy. On instance distribution, we're setting up the Auto Scaling group to launch only EC2 Spot Instances and use the `capacity-optimized` Spot Allocation Strategy. This makes Auto Scaling launch instances from the Spot capacity pool with optimal capacity for the number or instances that are launching. Deploying this way helps you make the most efficient use of spare EC2 capacity.
- On the `overrides` section, we're configuring 7 different instance types that we can use on our ECS cluster (across 3 AZs, means we can get capacity from 21 different Spot capacity pools). 

Once the deployment is complete, let's move back to the capacity provider demo repo and start work on setting up cluster auto scaling.

```bash
cd ~/environment/ecsdemo-capacityproviders/ec2
```

### Enable Cluster Auto Scaling

As we did in the previous section, we are going to once again create a capacity provider for the Spot Instances Auto Scaling group we just created. We'll also enable managed cluster autoscaling on it. Let's do that now.

```bash
# Get the required cluster values needed when creating the capacity provider
export spot_asg_name=$(aws cloudformation describe-stacks --stack-name ecsworkshop-base | jq -r '.Stacks[].Outputs[] | select(.ExportName | contains("EC2SpotASGName"))| .OutputValue')
export spot_asg_arn=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $spot_asg_name | jq .AutoScalingGroups[].AutoScalingGroupARN)
export spot_capacity_provider_name=$(echo "EC2Spot$(date +'%s')")
# Creating capacity provider
aws ecs create-capacity-provider \
     --name $spot_capacity_provider_name \
     --auto-scaling-group-provider autoScalingGroupArn="$spot_asg_arn",managedScaling=\{status="ENABLED",targetCapacity=80\},managedTerminationProtection="DISABLED" \
     --region $AWS_REGION
```

- *Note*: If you get an error that the capacity provider already exists because you've created it in the workshop before, just move on to the next step.

- In order to create a capacity provider with cluster auto scaling enabled, we need to have an auto scaling group created prior. We did this earlier in this section when we added the EC2 capacity to the ECS cluster. We run a couple of cli calls to get the Auto Scaling group details which is required for the next command where we create the capacity provider.

- The next command is creating a capacity provider via the AWS CLI. Let's look at the parameters and explain what their purpose:

  - `--name`: This is the human readable name for the capacity provider that we are creating.
  - `--auto-scaling-group-provider`: There is quite a bit here, let's unpack one by one:
  
    - `autoScalingGroupArn`: The ARN of the auto scaling group for the cluster autoscaler to use.
    - `managedScaling`: This is where we enable/disable cluster auto scaling. We also set `targetCapacity`, which determines at what point in cluster utilization do we want the auto scaler to take action.
    - `managedTerminationProtection`: Enable this parameter if you want to ensure that prior to an EC2 instance being terminated (for scale-in actions), the auto scaler will only terminate instances that are not running tasks.

Now that we have a capacity provider created, we need to associate it with the ECS Cluster. As we created an On-Demand Auto Scaling capacity provider on the previous section, we'll add the Spot Auto Scaling group and assign both capacity providers the same weight on the cluster default capacity provider strategy, with a base of 1 initial task scheduled on the on-demand capacity provider. With this configuration, the first task will be scheduled on the on-demand capacity provider. Subsequent tasks will be scheduled 50% on the Spot Auto Scaling capacity provider and the other 50% on the On-Demand Auto Scaling capacity provider.  

```bash
aws ecs put-cluster-capacity-providers \
--cluster container-demo \
--capacity-providers $capacity_provider_name $spot_capacity_provider_name \
--default-capacity-provider-strategy capacityProvider=$capacity_provider_name,weight=1,base=1 capacityProvider=$spot_capacity_provider_name,weight=1,base=0
```

You will get a json response indicating that the cluster update has been applied.

### Redeploy an EC2 backed ECS service
