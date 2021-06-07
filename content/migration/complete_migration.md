---
title: "Migrate our workload"
chapter: false
weight: 55
---

### We have a container image, now what?

Now we need to get our containerized application up and running in a production ready environment.
If you are new to containers, this can turn out to be a steep learning curve when getting started.
At this point you could run this container on an EC2 host and write your own glue logic to script everything together to ensure your container stays up and running and scales as needed.
This is most certainly not the recommended approach, and hence why we have container orchestrators which were designed to solve these problems.

A container orchestration service is responsible for coordinating the "where" and "how" for your containers.
This is a very simple explanation, but there is a lot of power that comes with an orchestrator and the benefits are abundant.

When we deploy our application we want to take advantage of some of the power that comes with an orchestrator.
Here are some of the things that we will want to implement to be elastic, secure, operationally aware, and fast:

- Service autoscaling: We want to scale our service in and out to meet the demand of our applications users.
- Health checks: If the application is unresponsive or fails, we need the orchestrator to replace it.
- Logging/Monitoring: We need insight into our application logs as well as system level metrics like CPU and Memory.

In this workshop we're going to use Amazon Elastic Container Service to deploy our container workload.
We could do this in the AWS Console, via CloudFormation/Terraform, as well as the AWS CDK.
While those tools are powerful and have their benefits, we're going to take advantage of an opinionated CLI that will help build our environment employing recommended practices.
The tool we will be using is the [AWS Copilot CLI](ihttps://aws.github.io/copilot-cli/).

### AWS Copilot

The Copilot CLI is a tool for developers to build, release, and operate production-ready containerized applications on AWS App Runner, Amazon ECS, and AWS Fargate.
From getting started, pushing to staging, and releasing to production, Copilot can help manage the entire lifecycle of your application development.

Let's get started with using the Copilot CLI to get our application deployed.

### Define our application

Copilot starts with defining our application. Look at this as in terms of a Service Oriented Architecture (SOA).
One application may be comprised of one, tens, hundreds, or thousands of services.

We'll start by issuing a command to create the structure of our application.

```bash
copilot app init
```

The CLI will ask some questions, and then it will begin to create the skeleton framework for our application.
It will ask you to name the application and for this workshop we will name our application `migration-demo`, then hit enter.
This will take a couple of minutes.

This command is not going to create our environments, we'll get into that in just a moment.
At a high level, copilot is going to provision an S3 Bucket, KMS Key, as well as some other boilerplate for the application.
For more information, please refer to the [documentation](https://aws.github.io/copilot-cli/docs/concepts/applications/)

Next, we're going to deploy a test environment.

### Define our environment

When migrating applications from one environment to the next, it's important to understand the requirements of the existing application.
Some things we need to understand are:

- Network/Communication requirements
- Data requirements (Database communication, latency requirements, etc)
- DNS/Service Discovery

Having a clear understanding of the current picture will help us avoid issues as we migrate.
We mentioned earlier that we want to keep the same VPC to enable other services to communicate to the user api service.
The Copilot CLI can create a new VPC on our behalf with recommend practices built in, but since we are keeping the VPC we will create our environment and explicitely pass in the details of the existing VPC.

Run the following command to get started with deploying our test environment:

```bash
# We need the VPC ID, so we'll grab it using the AWS CLI
vpc_id=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=BuildEc2EnvironmentStack/DemoVPC --query Vpcs[].VpcId --output text)
# Next we'll initialize our environment passing in the VPC ID for our existing VPC
copilot env init --import-vpc-id $vpc_id --name test --app migration-demo
```

We will be prompted with a series of questions. 

- Which credentials would you like to use to create test?
  - Choose the default profile for our credentials.
- Which public/private subnets would you like to use?
  - Choose all of the subnets for public and private

Next, copilot is going to define and then build out our environment.
An environment includes the resources and "infrastructure" in which your services will be deployed to.
This includes the VPC, ECS Cluster, IAM roles, Security Groups, etc.
Copilot is building all of this using [AWS Cloudformation](https://aws.amazon.com/cloudformation/) behind the scenes, which is where the boilerplate infrastructure as code is managed.
For more information on what copilot does when creating environments, see the [documentation](https://aws.github.io/copilot-cli/docs/concepts/environments/)

This step will take a few minutes, but when it's done we will have an environment ready for us to deploy our container onto. Yes, it's really this easy!
Feel free to navigate in the AWS Console to see what resources were created, here are some places to look:
- ECS Clusters: https://us-west-2.console.aws.amazon.com/ecs/home?region=us-west-2#/clusters
- CloudFormation: https://us-west-2.console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks?filteringStatus=active&filteringText=&viewNested=true&hideStacks=false

You can also get the details of your environment using the Copilot CLI:

```bash
copilot env show -n test
```

Ok, so we now have our application and environment defined and built.
It's time to get our container image deployed!

### Define and deploy our service

One of the awesome things about containers is that once you've written your code, running it locally is as easy as typing docker run. 
Copilot makes running those same containers on AWS as easy as typing copilot init. 
Copilot will build your image, push it to Amazon ECR and set up all the infrastructure to run your service in a scalable and secure way.

Let's get started by initializing our service and walking through the guided experience.

```bash
copilot svc init
```

Once again we are prompted with a series of questions that will help Copilot understand how to deploy our service.

- Which service type best represents your service's architeture: 
  - Choose the Backend Service as this particular service is internal and not internet facing or requiring a load balancer.
- What do you want to name this Backend Service:
  - Name the service `userapi`
- Which Dockerfile would you like to use for userapi? 
  - We are prompted to choose a Dockerfile, upstream image, or custom field. We will choose Dockerfile as we created this earlier.

Copilot will create our manifest file locally as well as the ECR Repository for our container image to be stored.
Once the process is done, let's take a look at the manifest file.

```bash
cat copilot/userapi/manifest.yml
```

You may notice that there are some fields with values in the manifest that look familiar to what we defined in our Dockerfile earlier.
This is because copilot was able to look inside of our Dockerfile and translate those values into the manifest.
These values will be used when deploying our application to Amazon ECS.

```yaml
# Configuration for your containers and service.
image:
  # Docker build arguments. For additional overrides: https://aws.github.io/copilot-cli/docs/manifest/backend-service/#image-build
  build: Dockerfile
  # Port exposed through your container to route traffic to it.
  port: 8080
  healthcheck:
    # Container health checks: https://aws.github.io/copilot-cli/docs/manifest/backend-service/#image-healthcheck
    command: ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
    interval: 5s
    retries: 2
    timeout: 5s
    start_period: 5s
```

At this point the manifest looks good, but there are some things missing that our service needs to function like it does when running on EC2.
Here's what we need to address prior to deploying our service:

- Enable our service to talk to the DynamoDB table via an IAM role
- Add a security group to our service that will enable other hosts with that security group attached to talk to one another.
- Add an environment variable to our service to know which DynamoDB table to talk to
- Add some basic autoscaling based off of CPU, as we know our application generally needs to scale on CPU when traffic spikes.

#### Addons

Additional AWS resources, referred to as "addons" in the CLI, are any additional AWS services that a service manifest does not integrate by default.
For example, an addon can be a DynamoDB table, an S3 bucket, or an RDS Aurora Serverless cluster that your service needs to read or write to.

We need to create an IAM role that will allow our container to interact with our DynamoDB table.
We'll do this by creating an addons directory under our service in the copilot directory, and add our IAM policy there which is defined as Cloudformation.

Run the command below to create the directory and paste the Cloudformation template.

```bash
# Create the addons directory
mkdir -p copilot/userapi/addons/
# Create the Cloudformation template and paste it in the addons directory
cat << EOF >> copilot/userapi/addons/ddb_iam.yml
Parameters:
    App:
        Type: String
        Description: Your application's name.
    Env:
        Type: String
        Description: The environment name your service, job, or workflow is being deployed to.
    Name:
        Type: String
        Description: The name of the service, job, or workflow being deployed.
Resources:
    UsersTablePolicy:
        Type: AWS::IAM::ManagedPolicy
        Properties:
            PolicyDocument:
                Version: 2012-10-17
                Statement:
                    - Sid: DDBActions
                      Effect: Allow
                      Action:
                        - dynamodb:BatchGetItem
                        - dynamodb:GetRecords
                        - dynamodb:GetShardIterator
                        - dynamodb:Query
                        - dynamodb:GetItem
                        - dynamodb:Scan
                        - dynamodb:ConditionCheckItem
                        - dynamodb:BatchWriteItem
                        - dynamodb:PutItem
                        - dynamodb:UpdateItem
                        - dynamodb:DeleteItem
                        - dynamodb:DescribeTable
                      Resource:
                        - !Sub 'arn:aws:dynamodb:\${AWS::Region}:\${AWS::AccountId}:table/UsersTable-\${Env}'

Outputs:
    # 1. You also need to output the IAM ManagedPolicy so that Copilot can inject it to your ECS task role.
    UsersTableAccessPolicyArn:
        Description: "The ARN of the ManagedPolicy to attach to the task role."
        Value: !Ref UsersTablePolicy
EOF
```

Looking at the CloudFormation template, we are creating an IAM policy that will allow our service to talk to the proper DynamoDB table.
Copilot passes in environment parameters to the template for us to reuse if needed, and we are using the environment name to dynamically choose our table on deployment.
Finally, in order for our service to get the IAM Policy attached we simple output the policy as a CloudFormation output and copilot will handle the rest!

Onto updating the manifest for the remaining items.

#### Updating the manifest file

The next thing we need for our application is the security group.
We want to use a pre-existing security group to enable our existing applications in the previous environment to communicate with our new service.

```bash
# We need the Security Group ID, so we'll grab it using the AWS CLI
sec_grp_id=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values=BuildEc2EnvironmentStack/ApplicationASG --query SecurityGroups[].GroupId --output text)
```

Next, we need to add an environment variable for our service to know which DynamoDB table to communicate with.
Let's get these values into the manifest file by running the command below:

```bash
cat << EOF >> copilot/userapi/manifest.yml

environments:
  test:
    variables:
      DYNAMO_TABLE: UsersTable-test
    network:
      vpc:
        security_groups: ['${sec_grp_id}']
EOF
```

Because each environment will have different values, you can see we are setting these values for the test environment.

The last thing we want to do is to add autoscaling based off of average CPU utilization for our service. 
Normally this would take a few steps to get this enabled, but with Copilot it's as easy as defining our count, range, and scale metric in the manifest.

Using your text editor of choice, modify the section where it says `count: 1` to the following:

```yaml
count:
  range: 1-10
  cpu_percentage: 50
```

This instructs Copilot to create an autoscaling policy for our service based on an average CPU utilization of 50% for three datapoints.

#### Deployment time

It's time to deploy our service! 
Run the following to start the deployment:

```bash
copilot svc deploy
```

This will take a couple of minutes, so let's talk through what is happening during this process.

1) Copilot will build the Docker image, tag it, and push it to the image repository in Amazon ECR.
2) It creates a Task definiton and service in Amazon ECS, which is responsible for ensuring that our containers are up and running.
3) Logging, IAM policies, and Service Discovery name are created for our service.
4) Service autoscaling policies are created for our service to autoscale between one and ten tasks, based on an average CPU utilization of 50%.

Once it's done, let's do some testing.

To start, we can execute a shell in the container, let's do that now.

```bash
copilot svc exec
```

Once in the shell, run the following commands to confirm our application is able to talk to the DynamoDB table and work as we expect.

```bash
bash
curl localhost:8080/health
echo
curl -s localhost:8080/all_users
echo
exit
exit
```

Perfect, our service is working as we expect and it's able to talk to the database succesfully!
Let's start an ssm session back to our EC2 instance and test that we're able to communicate from that instance to our service via service discovery.
In this scenario we are testing that the security group that we added to the task will allow communication from other hosts that have that security group attached.

```bash
# Grab the instance ID for us to access
instance_id=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:Name,Values=BuildEc2EnvironmentStack/ApplicationASG --query Reservations[].Instances[0].InstanceId --output text)
# Start a shell via SSM session manager
aws ssm start-session --target $instance_id
```

Now let's see if we can talk to our container via service discovery (which was created by Copilot):

```bash
# Curl the health endpoint
curl http://userapi.migration-demo.local:8080/health
# Curl the all_users endpoint
curl http://userapi.migration-demo.local:8080/all_users
```

Success! We are now succesfully running our code as a container running on Amazon ECS.
At this point any applications talking to this service could flip the hostname for the previous version of the service to the service discovery endpoint.

Now that we're done, let's clean up the resources.