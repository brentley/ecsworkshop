---
title: "Fargate Capacity Provider Setup"
disableToc: true
hidden: true
---
 
#### Enable Fargate capacity provider on existing cluster

First, we will update our ECS cluster to enable the fargate capacity provider. Because the cluster already exists, we will do it via the CLI as it presently can't be done via the console on existing clusters.

Using the AWS CLI, run the following command:

```bash
aws ecs put-cluster-capacity-providers \
--cluster container-demo \
--capacity-providers FARGATE FARGATE_SPOT \
--default-capacity-provider-strategy \
capacityProvider=FARGATE,weight=1,base=1 \
capacityProvider=FARGATE_SPOT,weight=2
```

With this command, we're adding the Fargate and Fargate Spot capacity providers to our ECS Cluster. Let's break it down by each input:

 - `--cluster`: we're simply passing in our cluster name that we want to update the capacity provider strategy for.
 - `--capacity-providers`: this is where we pass in our capacity providers that we want enabled on the cluster. Since we do not use EC2 backed ECS tasks, we don't need to create a cluster capacity provider prior to this. With that said, there are only the two options when using Fargate.
 - `--default-capacity-provider-strategy`: this is setting a default strategy on the cluster; meaning, if a task or service gets deployed to the cluster without a strategy and launch type set, it will default to this. Let's break the base/weight down to get a better understanding.

The base value designates how many tasks, at a minimum, to run on the specified capacity provider. Only one capacity provider in a capacity provider strategy can have a base defined.

The weight value designates the relative percentage of the total number of launched tasks that should use the specified capacity provider. For example, if you have a strategy that contains two capacity providers, and both have a weight of 1, then when the base is satisfied, the tasks will be split evenly across the two capacity providers. Using that same logic, if you specify a weight of 1 for capacityProviderA and a weight of 4 for capacityProviderB, then for every one task that is run using capacityProviderA, four tasks would use capacityProviderB. 

In the command we ran, we are stating that we want a minimum of 1 Fargate task as our base, and after that, for every one task using Fargate strategy, two tasks will use Fargate Spot.

Next, let's clone the service repo and navigate to the `fargate` directory, this is where we'll do the rest of the work.

```bash
cd ~/environment
git clone git@github.com:adamjkeller/ecsdemo-capacityproviders.git
cd ecsdemo-capacityproviders/fargate
```

#### Meet the application

The application we are deploying is a simple API that will return the arns of tasks running in the cluster, as well as the provider that they are using.
Lastly, the application will tell us the ARN of the container we landed on and the provider that it is using. It's a simple application that allows us to see in realtime the strategy in action.

Here is what we should see when we hit the load balancer URL after we deploy the application:

```json
{"ALL_TASKS":{"arn:aws:ecs:us-west-2:333258026273:task/418624db-7260-4ba8-8704-4b057982b571":"FARGATE_SPOT","arn:aws:ecs:us-west-2:333258026273:task/722e89d9-ad20-43ff-8f1c-14f532cbf197":"FARGATE_SPOT","arn:aws:ecs:us-west-2:333258026273:task/73f5e189-ffed-4e3c-ba47-71b37faf2427":"FARGATE_SPOT","arn:aws:ecs:us-west-2:333258026273:task/9dd917d2-34fd-439b-b11f-10b3d7cf9e33":"FARGATE_SPOT","arn:aws:ecs:us-west-2:333258026273:task/a2c3e7f9-0609-4dbb-9a66-cc35a612d821":"FARGATE_SPOT","arn:aws:ecs:us-west-2:333258026273:task/b3c05d52-bc25-4e86-aa52-48da5e03cefa":"FARGATE_SPOT","arn:aws:ecs:us-west-2:333258026273:task/ce7072f1-7c9e-474b-b56b-daf7f3812f05":"FARGATE","arn:aws:ecs:us-west-2:333258026273:task/cf9221af-2de4-4902-92e7-13ede592fbb5":"FARGATE","arn:aws:ecs:us-west-2:333258026273:task/d238d331-fed7-454a-a220-35e2abd11696":"FARGATE","arn:aws:ecs:us-west-2:333258026273:task/de884884-5f84-4e09-ab1e-78e56c5a57d8":"FARGATE"},"MY_ARN":"arn:aws:ecs:us-west-2:333258026273:task/418624db-7260-4ba8-8704-4b057982b571","MY_STRATEGY":"FARGATE_SPOT"}
```

Like our previous services, we are using the CDK to deploy. Let's go ahead and deploy it, and then do some deep dive and review the code!

#### Deploy 

Review what changes are being proposed:

```bash
cdk diff
```

Deploy the service

```bash
cdk deploy --require-approval never
```

#### Code Review

{{%expand "Let's Dive in" %}}

As we've gone over in other sections, we are importing platform related items using the BasePlatform construct. For the sake of time, we will skip the review.

This deployment pattern looks very similar to what we deployed for the frontend service. We are using a high level construct via the CDK which will build all of the resources we need to connect our application to a frontend load balancer.

```python
class CapacityProviderFargateService(core.Stack):
    
    def __init__(self, scope: core.Stack, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        self.base_platform = BasePlatform(self, self.stack_name)

        self.task_image = aws_ecs_patterns.ApplicationLoadBalancedTaskImageOptions(
            image=aws_ecs.ContainerImage.from_registry("adam9098/ecsdemo-capacityproviders:latest"),
            container_port=5000,
        )

        self.load_balanced_service = aws_ecs_patterns.ApplicationLoadBalancedFargateService(
            self, "FargateCapacityProviderService",
            service_name='ecsdemo-capacityproviders-fargate',
            cluster=self.base_platform.ecs_cluster,
            cpu=256,
            memory_limit_mib=512,
            desired_count=10,
            public_load_balancer=True,
            task_image_options=self.task_image,
            platform_version=aws_ecs.FargatePlatformVersion.VERSION1_4
        )
```

The only difference you may notice in the code is that we remove the default launch type of being Fargate. The reason behind this, is we want to let the cluster choose the default capacity provider strategy (which we defined earlier). By removing the Launch type, the cluster capacity provider will decide the launch type(s) based on the default.

We are also creating an IAM policy statement that will be attached to our service. This is another one of the native integrations ECS has with the AWS Cloud. We are creating a policy that is allowing the containers to list and describe ecs tasks in the AWS account, and attaching it to the service. This will ensure that every time a task is spun up by it's service, it will have the IAM permissions to make the calls to AWS resources.

```python
        self.cfn_resource = self.load_balanced_service.service.node.children[0]
        
        self.cfn_resource.add_deletion_override("Properties.LaunchType")
            
        self.load_balanced_service.task_definition.add_to_task_role_policy(
            aws_iam.PolicyStatement(
                actions=[
                    'ecs:ListTasks',
                    'ecs:DescribeTasks'
                ],
                resources=['*']
            )
        )
```
{{% /expand %}}

#### Post deploy

Once the deployment is finished, copy the load balancer URL, and paste it into your browser.

In the browser, you will see the json response. Go ahead and refresh a few times. You should see that as you are routed to different containers via the load balancer, fargate and fargate spot containers will be serving the respone.

#### Review

Here's what we accomplished in this section of the workshop:

- We updated our ECS Clusters default Capacity Provider strategy, which ensures that if no launch type or capacity provider strategy is set, services will get deployed using the default mix of fargate and fargate spot.
- We deployed a service with multiple tasks, and saw the Capacity Provider choose what type of Fargate task to launch (Fargate/Fargate Spot)
- While this was just an example, this could translate to many real world use cases. By simply setting the base and weights between Fargate and Fargate Spot, we can take advantage of the cost savings of Fargate Spot in our every day workloads. Of course, it's important to understand that Spot tasks can be terminated at any time (for more information, see [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-capacity-providers.html#fargate-capacity-providers-termination)), when capacity requirements change. With that said, that is why we set the default strategy to be a mix of Fargate and Fargate spot to ensure that if spot tasks are terminated, we still have our service up using Farate on demand.
- In this section, we deployed using a mix of strategies (Fargate and Fargate Spot). You can also stick to one strategy (Fargate or Fargate Spot), and this would be defined when you deploy your service.

#### Cleanup

Run the cdk command to delete the service (and dependent components) that we deployed.

```bash
cdk destroy -f
```

#### Up Next

In the next section, we're going to:

- Add EC2 instances to our cluster
- Change the strategy to use EC2 as the default Capacity Provider
- Enable Cluster Auto Scaling 
- Deploy a service, trigger load to the service so desired count exceeds current capacity, and watch as the cluster autoscaling takes action.