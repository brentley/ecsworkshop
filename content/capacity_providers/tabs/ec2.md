---
title: "Deploy ECS Cluster Auto Scaling"
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
        
        core.CfnOutput(self, "EC2AutoScalingGroupName", value=self.asg.auto_scaling_group_name, export_name="EC2ASGName")
        ##### END CAPACITY PROVIDER SECTION #####
```

Now, update the cluster using the cdk.

```bash
cdk deploy --require-approval never
```

By adding that small section of code, all of the necessary components to add EC2 instances to the cluster will be created. This includes an Auto Scaling Group, Launch Configuration, ECS Optimized AMI, etc. For more information, see the [official cdk documentation.](https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_ecs/Cluster.html#aws_cdk.aws_ecs.Cluster.add_capacity)

Once the deployment is complete, let's move back to the capacity provider demo repo and start work on setting up cluster auto scaling.

```bash
cd ~/environment/ecsdemo-capacityproviders/ec2
```

### Enable Cluster Auto Scaling

As we did in the previous section, we are going to once again create a capacity provider. This time; however, it will be a capacity provider to enable managed cluster auto scaling. Let's do that now.

```bash
# Get the required cluster values needed when creating the capacity provider
export asg_name=$(aws cloudformation describe-stacks --stack-name ecsworkshop-base | jq -r '.Stacks[].Outputs[] | select(.ExportName | contains("EC2ASGName"))| .OutputValue')
export asg_arn=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $asg_name | jq .AutoScalingGroups[].AutoScalingGroupARN)
export capacity_provider_name=$(echo "EC2$(date +'%s')")
# Creating capacity provider
aws ecs create-capacity-provider \
     --name $capacity_provider_name \
     --auto-scaling-group-provider autoScalingGroupArn="$asg_arn",managedScaling=\{status="ENABLED",targetCapacity=80\},managedTerminationProtection="DISABLED" \
     --region us-west-2
```

- *Note*: If you get an error that the capacity provider already exists because you've created it in the workshop before, just move on to the next step.

- In order to create a capacity provider with cluster auto scaling enabled, we need to have an auto scaling group created prior. We did this earlier in this section when we added the EC2 capacity to the ECS cluster. We run a couple of cli calls to get the autoscale group details which is required for the next command where we create the capacity provider.

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
--capacity-providers $capacity_provider_name \
--default-capacity-provider-strategy capacityProvider=$capacity_provider_name,weight=1,base=1
```

You will get a json response indicating that the cluster update has been applied, now it's time to deploy a service and test this functionality out!


### Deploy an EC2 backed ECS service

First, as we've done previously, we will run a `diff` on what presently exists, and what will be deployed via the cdk.

```bash
cdk diff
```

Review the changes, you should see all new resources being created for this service as it hasn't been deployed yet. So on that note, let's deploy it!

```bash
cdk deploy --require-approval never
```

Once the service is deployed, take note of the load balancer URL output. Copy that and paste it into the browser.


### Examine the current deployment

What we did above was deploy a service that runs one task. With the current EC2 instances that are registered to the cluster, there is more than enough capacity to run our service.

Navigate to the console, and select the container-demo cluster. Click the ECS Instances tab, and review the current capacity.

![clustercapacity](/images/ec2_ecs_cluster.png)

As you can see, we have plenty of capacity to support a few more tasks. But what happens if we need to run more tasks than what we have current capacity to run?

- As operators of the cluster, we have to think about how to scale the backend EC2 infrastructure that runs our tasks (of course, this is for EC2 backed tasks, with Fargate, this is not a concern of the operator as the EC2 backend is obfuscated). 
- We also have to be mindful of scaling the application. It's a good practice to enable autoscaling on the services to ensure the application can meet the demand of it's end users.

This poses a challenge when operating an EC2 backed cluster, as scaling needs to be considered in two places. With the cluster autoscaling being enabled, now the orchestrator will scale the backend infrastucture to meet the demand of the application. This empowers teams that need EC2 backed tasks, to think "application first", rather than think about scaling the infrastructure.


### Scale the service beyond the current capacity available

We'll do it live! Go back into the deployment configuration (`~/environment/ecsdemo-capacityproviders/ec2/app.py`), and do the following:

Change the desired_count parameter from `1` to `10`.

```python
        self.load_balanced_service = aws_ecs_patterns.ApplicationLoadBalancedEc2Service(
            self, "EC2CapacityProviderService",
            service_name='ecsdemo-capacityproviders-ec2',
            cluster=self.base_platform.ecs_cluster,
            cpu=256,
            memory_limit_mib=512,
            #desired_count=1,
            desired_count=10,
            public_load_balancer=True,
            task_image_options=self.task_image,
        )
```

Now, save the changes, and let's deploy.

```bash
cdk deploy --require-approval never
```

Let's walk through what we did and what is happening.

- We are modifying our task count for the service to go from one, to ten. This will stretch us beyond the capacity that presently exists for the cluster.
- The capacity provider assigned to the cluster will recognize that the target capacity of the total cluster resources is above 80%. This will trigger an autoscaling event to scale EC2 to get the capacity back to 80% or under.

If you navigate to the ECS console for the container-demo cluster, you'll notice that there are ten tasks attempting to run.

![clustercapacity](/images/cp_10tasks.png)

Next, when you select the `ECS Instances` tab, you will see that there are only two instances running. Looking at the `Pending tasks count` however, we see that there are four tasks waiting to be scheduled. This is due to lack of resource availability.

![clustercapacity](/images/cp_pending_tasks.png)

Over the course of the next couple of minutes, behind the scenes a target tracking scaling policy is triggering a Cloudwatch alarm to enable the auto scale group to scale out.
Shortly after, we will begin to see new EC2 instances register to the cluster. This will then be followed by the tasks getting scheduled on to those instances.

Once done, the console should now look something like below:

All tasks should be in a `RUNNING` state.
![running](/images/cp_all_tasks_running.png)

More EC2 instances are registered to the ECS Cluster.
![ec2](/images/cp_ec2_full.png)


### Scale the service back down to one

Now that we've seen cluster auto scaling scale out the backend EC2 infrastructure, let's drop the count back to one and watch as it will scale our infrastructure back in.

We'll do it live! Go back into the deployment configuration (`~/environment/ecsdemo-capacityproviders/ec2/app.py`), and do the following:

Change the desired_count parameter from `10` to `1`.

```python
        self.load_balanced_service = aws_ecs_patterns.ApplicationLoadBalancedEc2Service(
            self, "EC2CapacityProviderService",
            service_name='ecsdemo-capacityproviders-ec2',
            cluster=self.base_platform.ecs_cluster,
            cpu=256,
            memory_limit_mib=512,
            desired_count=1,
            #desired_count=10,
            public_load_balancer=True,
            task_image_options=self.task_image,
        )
```

Now, save the changes, and let's deploy.

```bash
cdk deploy --require-approval never
```

That's it. Now, over the course of the next few minutes, the cluster autoscaler will recognize that we are well above capacity requirements, and will scale the EC2 instances back in.


#### Review

What we accomplished in this section of the workshop is the following:

- Created an capacity provider for EC2 backed tasks that has managed cluster auto scaling enabled.
- We deployed a service with one task and plenty of backend capacity, and then scaled out to ten tasks. This caused the managed cluster auto scaling to trigger a scale out event to have the backend infrastructure meet the availability requirements of the tasks.
- We then scaled the service back to one, and watched as the cluster autoscaler scaled the EC2 instances back in to ensure that we weren't over provisioned.

#### Cleanup

Run the cdk command to delete the service (and dependent components) that we deployed.

```bash
cdk destroy -f
```

Next, go back to the ECS Cluster in the console. In the top right, select `Update Cluster`.

![updatecluster](/images/cp_update_cluster.png)

Under `Default capacity provider strategy`, click the `x` next to all of the strategies until there are no more left to remove. Once you've done that, click `Update`.

![deletecapprovider](/images/cp_delete_default.png)


That's it! Great job! Let's move on to the next section...